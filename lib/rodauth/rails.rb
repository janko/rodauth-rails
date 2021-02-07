require "rodauth/rails/version"
require "rodauth/rails/railtie"

module Rodauth
  module Rails
    class Error < StandardError
    end

    # This allows the developer to avoid loading Rodauth at boot time.
    autoload :App, "rodauth/rails/app"

    @app = nil
    @middleware = true

    class << self
      def rodauth(name = nil)
        url_options = ActionMailer::Base.default_url_options

        scheme   = url_options[:protocol] || "http"
        port     = url_options[:port]
        port   ||= Rack::Request::DEFAULT_PORTS[scheme] if Gem::Version.new(Rack.release) < Gem::Version.new("2.0")
        host     = url_options[:host]
        host    += ":#{port}" if port

        rack_env = {
          "HTTP_HOST"       => host,
          "rack.url_scheme" => scheme,
        }

        scope = app.new(rack_env)

        scope.rodauth(name)
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
