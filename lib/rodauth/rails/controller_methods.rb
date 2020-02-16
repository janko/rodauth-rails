module Rodauth
  module Rails
    module ControllerMethods
      def self.included(controller)
        controller.helper_method(:rodauth) if controller.respond_to?(:helper_method)
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
