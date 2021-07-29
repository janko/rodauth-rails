require "rodauth/rails/version"
require "rodauth/rails/railtie"

module Rodauth
  module Rails
    class Error < StandardError
    end

    # This allows the developer to avoid loading Rodauth at boot time.
    autoload :App, "rodauth/rails/app"
    autoload :Auth, "rodauth/rails/auth"
    autoload :Model, "rodauth/rails/model"

    @app = nil
    @middleware = true

    LOCK = Mutex.new

    class << self
      def rodauth(name = nil, query: nil, form: nil, account: nil, **options)
        auth_class = app.rodauth(name)

        unless auth_class
          fail ArgumentError, "undefined rodauth configuration: #{name.inspect}"
        end

        LOCK.synchronize do
          unless auth_class.features.include?(:internal_request)
            auth_class.configure { enable :internal_request }
            warn "Rodauth::Rails.rodauth requires the internal_request feature to be enabled. For now it was enabled automatically, but this behaviour will be removed in version 1.0."
          end
        end

        if query || form
          warn "The :query and :form keyword arguments for Rodauth::Rails.rodauth have been deprecated. Please use the :params argument supported by internal_request feature instead."
          options[:params] = query || form
        end

        if account
          options[:account_id] = account.id
        end

        instance = auth_class.internal_request_eval(options) do
          @account = account.attributes.symbolize_keys if account
          self
        end

        instance
      end

      def model(name = nil, **options)
        Rodauth::Rails::Model.new(app.rodauth(name), **options)
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
