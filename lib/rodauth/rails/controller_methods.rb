module Rodauth
  module Rails
    module ControllerMethods
      def self.included(controller)
        # ActionController::API doesn't have helper methods
        if controller.respond_to?(:helper_method)
          controller.helper_method :rodauth
        end
      end

      def rodauth(name = nil)
        if name
          request.env["rodauth.#{name}"]
        else
          request.env["rodauth"]
        end
      end
    end
  end
end
