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
        app = Rodauth::Rails.app.new(@app)

        # allow the Rails app to call Rodauth methods that throw :halt
        catch(:halt) do
          app.call(env)
        end
      end
    end
  end
end
