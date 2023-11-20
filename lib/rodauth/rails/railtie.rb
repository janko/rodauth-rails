require "rodauth/rails/middleware"
require "rodauth/rails/controller_methods"
require "rodauth/rails/test"
require "rodauth/rails/routing"

require "rails"

module Rodauth
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "rodauth.middleware", after: :load_config_initializers do |app|
        if Rodauth::Rails.middleware?
          app.middleware.use Rodauth::Rails::Middleware
        end
      end

      initializer "rodauth.controller" do
        ActiveSupport.on_load(:action_controller) do
          include Rodauth::Rails::ControllerMethods
        end
      end

      initializer "rodauth.routing" do
        ActionDispatch::Routing::Mapper.include Rodauth::Rails::Routing
      end

      initializer "rodauth.test" do
        # Rodauth uses RACK_ENV to set the default bcrypt hash cost
        ENV["RACK_ENV"] = "test" if ::Rails.env.test?

        ActiveSupport.on_load(:action_controller_test_case) do
          include Rodauth::Rails::Test::Controller
        end
      end
    end
  end
end
