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
          return unless account || logged_in?

          account_from_session unless account

          unless account
            clear_session
            return
          end

          @rails_account ||= instantiate_rails_account
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
          if only_json? && Rodauth::Rails.api_only?
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

        delegate :rails_routes, :rails_request, to: :scope

        private

        def instantiate_rails_account
          if defined?(ActiveRecord::Base) && rails_account_model < ActiveRecord::Base
            rails_account_model.instantiate(account.stringify_keys)
          elsif defined?(Sequel::Model) && rails_account_model < Sequel::Model
            rails_account_model.load(account)
          else
            fail Error, "unsupported model type: #{rails_account_model}"
          end
        end

        # Instances of the configured controller with current request's env hash.
        def _rails_controller_instance
          controller = rails_controller.new
          prepare_rails_controller(controller, rails_request)
          controller
        end

        if ActionPack.version >= Gem::Version.new("5.0")
          def prepare_rails_controller(controller, rails_request)
            controller.set_request! rails_request
            controller.set_response! rails_controller.make_response!(rails_request)
          end
        else
          def prepare_rails_controller(controller, rails_request)
            controller.send(:set_response!, rails_request)
            controller.instance_variable_set(:@_request, rails_request)
          end
        end

        def rails_api_controller?
          defined?(ActionController::API) && rails_controller <= ActionController::API
        end
      end
    end
  end
end
