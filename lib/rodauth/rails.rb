require "rodauth/rails/version"
require "rodauth/rails/railtie"

require "rack/utils"
require "stringio"

module Rodauth
  module Rails
    class Error < StandardError
    end

    # This allows the developer to avoid loading Rodauth at boot time.
    autoload :App, "rodauth/rails/app"
    autoload :Auth, "rodauth/rails/auth"

    @app = nil
    @middleware = true

    class << self
      def rodauth(name = nil, query: {}, form: {}, session: {}, account: nil, env: {})
        unless app.rodauth(name)
          fail ArgumentError, "undefined rodauth configuration: #{name.inspect}"
        end

        url_options = ActionMailer::Base.default_url_options

        scheme   = url_options[:protocol] || "http"
        port     = url_options[:port]
        port   ||= Rack::Request::DEFAULT_PORTS[scheme] if Gem::Version.new(Rack.release) < Gem::Version.new("2.0")
        host     = url_options[:host]
        host    += ":#{port}" if port

        content_type = "application/x-www-form-urlencoded" if form.any?

        rack_env = {
          "QUERY_STRING"    => Rack::Utils.build_nested_query(query),
          "rack.input"      => StringIO.new(Rack::Utils.build_nested_query(form)),
          "CONTENT_TYPE"    => content_type,
          "rack.session"    => {},
          "HTTP_HOST"       => host,
          "rack.url_scheme" => scheme,
        }.merge(env)

        scope    = app.new(rack_env)
        instance = scope.rodauth(name)

        # update session hash here to make it work with JWT session
        instance.session.merge!(session)

        if account
          instance.instance_variable_set(:@account, account.attributes.symbolize_keys)
          instance.session[instance.session_key] = instance.account_session_value
        end

        instance
      end

      # routing constraint that requires authentication
      def authenticated(name = nil, &condition)
        lambda do |request|
          rodauth = request.env.fetch ["rodauth", *name].join(".")
          rodauth.require_authentication
          rodauth.authenticated? && (condition.nil? || condition.call(rodauth))
        end
      end

      if ::Rails.gem_version >= Gem::Version.new("5.2")
        def secret_key_base
          ::Rails.application.secret_key_base
        end
      else
        def secret_key_base
          ::Rails.application.secrets.secret_key_base
        end
      end

      if ::Rails.gem_version >= Gem::Version.new("5.0")
        def api_only?
          ::Rails.application.config.api_only
        end
      else
        def api_only?
          false
        end
      end

      def configure
        yield self
      end

      attr_writer :app
      attr_writer :middleware

      def app
        fail Rodauth::Rails::Error, "app was not configured" unless @app

        @app.constantize
      end

      def middleware?
        @middleware
      end
    end
  end
end
