require "rodauth/rails/middleware"
require "rodauth/rails/controller_methods"
require "rodauth/rails/active_record_extension"

module Rodauth
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "rodauth.sequel" do
        ActiveSupport.on_load(:active_record) do
          Rodauth::Rails.sequel_connect if Rodauth::Rails.config.sequel_autoconnect
        end
      end

      initializer "rodauth.activerecord" do
        ActiveSupport.on_load(:active_record) do
          extend Rodauth::Rails::ActiveRecordExtension if Rodauth::Rails.config.activerecord_extension
        end
      end

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
