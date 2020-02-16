require "rodauth/rails/middleware"
require "rodauth/rails/controller_methods"
require "rodauth/rails/active_record_extension"

module Rodauth
  module Rails
    class Engine < ::Rails::Engine
      initializer "rodauth.sequel" do
        Rodauth::Rails.sequel_connect
      end

      initializer "rodauth.active_record" do
        ActiveRecord::Base.extend Rodauth::Rails::ActiveRecordExtension
      end

      initializer "rodauth.middleware" do |app|
        app.middleware.use Rodauth::Rails::Middleware
      end

      initializer "rodauth.controller" do
        ActionController::Base.include Rodauth::Rails::ControllerMethods
        ActionController::API.include Rodauth::Rails::ControllerMethods
      end
    end
  end
end
