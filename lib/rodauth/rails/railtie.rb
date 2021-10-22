require "rodauth/rails/middleware"
require "rodauth/rails/controller_methods"

require "rails"

module Rodauth
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "rodauth.middleware" do |app|
        app.middleware.use Rodauth::Rails::Middleware
      end

      initializer "rodauth.controller" do
        ActiveSupport.on_load(:action_controller) do
          include Rodauth::Rails::ControllerMethods
        end
      end

      initializer "rodauth.test" do
        # Rodauth uses RACK_ENV to set the default bcrypt hash cost
        ENV["RACK_ENV"] = "test" if ::Rails.env.test?
      end

      rake_tasks do
        load "rodauth/rails/tasks.rake"
      end
    end
  end
end
