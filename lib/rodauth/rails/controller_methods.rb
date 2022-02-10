module Rodauth
  module Rails
    module ControllerMethods
      def self.included(controller)
        # ActionController::API doesn't have helper methods
        if controller.respond_to?(:helper_method)
          controller.helper_method :rodauth, :current_account
        end
      end

      def current_account(name = nil)
        rodauth(name).rails_account || rodauth(name).login_required
      end

      def rodauth(name = nil)
        request.env.fetch ["rodauth", *name].join(".")
      end

      private

      def rodauth_response
        res = catch(:halt) { return yield }

        self.status = res[0]
        self.headers.merge! res[1]
        self.response_body = res[2]

        res
      end
    end
  end
end
