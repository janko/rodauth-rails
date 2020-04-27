require "rodauth/rails/middleware"
require "rodauth/rails/controller_methods"

module Rodauth
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "rodauth.middleware" do |app|
        app.middleware.use Rodauth::Rails::Middleware if Rodauth::Rails.config.middleware
      end

      initializer "rodauth.controller" do
        ActiveSupport.on_load(:action_controller) do
          include Rodauth::Rails::ControllerMethods
        end
      end
    end
  end
end
