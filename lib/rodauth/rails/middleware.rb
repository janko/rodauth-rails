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
        middleware = Rodauth::Rails.config.app
        middleware.new(@app).call(env)
      end
    end
  end
end
