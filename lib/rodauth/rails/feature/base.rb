require "active_support/concern"

module Rodauth
  module Rails
    module Feature
      module Base
        extend ActiveSupport::Concern

        included do
          auth_methods :rails_controller
          auth_value_methods :rails_account_model
          auth_cached_method :rails_controller_instance
        end

        def rails_account
          @rails_account = nil if account.nil? || @rails_account&.id != account_id
          @rails_account ||= instantiate_rails_account if account!
        end

        # Reset Rails session to protect from session fixation attacks.
        def clear_session
          rails_controller_instance.reset_session
        end

        # Default the flash error key to Rails' default :alert.
        def flash_error_key
          :alert
        end

        # Evaluates the block in context of a Rodauth controller instance.
        def rails_controller_eval(&block)
          rails_controller_instance.instance_exec(&block)
        end

        def rails_controller
          if only_json? && ::Rails.configuration.api_only
            ActionController::API
          else
            ActionController::Base
          end
        end

        def rails_account_model
          table = accounts_table
          table = table.column if table.is_a?(Sequel::SQL::QualifiedIdentifier) # schema is specified
          table.to_s.classify.constantize
        rescue NameError
          raise Error, "cannot infer account model, please set `rails_account_model` in your rodauth configuration"
        end

        delegate :rails_routes, :rails_cookies, :rails_request, to: :scope

        def session
          super
        rescue Roda::RodaError
          fail Rodauth::Rails::Error, "There is no session middleware configured, see instructions on how to add it: https://guides.rubyonrails.org/api_app.html#using-session-middlewares"
        end

        private

        def instantiate_rails_account
          if defined?(ActiveRecord::Base) && rails_account_model < ActiveRecord::Base
            if account_id
              rails_account_model.instantiate(account.stringify_keys)
            else
              rails_account_model.new(account)
            end
          elsif defined?(Sequel::Model) && rails_account_model < Sequel::Model
            rails_account_model.load(account)
          else
            fail Error, "unsupported model type: #{rails_account_model}"
          end
        end

        # Instance of the configured controller with current request's env hash.
        def _rails_controller_instance
          controller = rails_controller.new
          controller.set_request! rails_request
          controller.set_response! rails_controller.make_response!(controller.request)
          controller
        end
      end
    end
  end
end
