module Rodauth
  module Rails
    module ControllerMethods
      def self.included(controller)
        # ActionController::API doesn't have helper methods
        if controller.respond_to?(:helper_method)
          controller.helper_method :rodauth, :current_account
        end
      end

      def rodauth(name = nil)
        request.env.fetch ["rodauth", *name].join(".")
      end

      def current_account(name = nil)
        model = rodauth(name).rails_account_model
        id = rodauth(name).session_value

        @current_account ||= {}
        @current_account[name] ||= fetch_account(model, id) do
          rodauth(name).clear_session
          rodauth(name).login_required
        end
      end

      private

      def fetch_account(model, id, &not_found)
        if defined?(ActiveRecord::Base) && model < ActiveRecord::Base
          begin
            model.find(id)
          rescue ActiveRecord::RecordNotFound
            not_found.call
          end
        elsif defined?(Sequel::Model) && model < Sequel::Model
          begin
            model.with_pk!(id)
          rescue Sequel::NoMatchingRow
            not_found.call
          end
        else
          fail Error, "unsupported model type: #{model}"
        end
      end

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
