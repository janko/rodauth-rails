require "rodauth/rails/railtie"

module Rodauth
  module Rails
    class Error < StandardError
    end

    # This allows the developer to avoid loading Rodauth at boot time.
    autoload :App, "rodauth/rails/app"

    def self.configure
      yield self
    end

    @app = nil
    @middleware = true

    class << self
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
