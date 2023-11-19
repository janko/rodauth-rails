module Rodauth
  module Rails
    # Middleware that's added to the Rails middleware stack. Normally the main
    # Roda app could be used directly, but this trick allows the app class to
    # be reloadable.
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) if asset_request?(env)

        app = Rodauth::Rails.app.new(@app)

        # allow the Rails app to call Rodauth methods that throw :halt
        catch(:halt) do
          app.call(env)
        end
      end

      # Check whether it's a request to an asset managed by Sprockets or Propshaft.
      def asset_request?(env)
        return false unless ::Rails.configuration.respond_to?(:assets)

        env["PATH_INFO"] =~ %r(\A/{0,2}#{::Rails.configuration.assets.prefix})
      end
    end
  end
end
