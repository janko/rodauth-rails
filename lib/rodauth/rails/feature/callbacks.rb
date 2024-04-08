module Rodauth
  module Rails
    module Feature
      module Callbacks
        extend ActiveSupport::Concern

        private

        def _around_rodauth
          rails_controller_instance.instance_variable_set(:@_action_name, current_route.to_s)

          rails_controller_around { super }
        end

        # Runs controller callbacks and rescue handlers around Rodauth actions.
        def rails_controller_around
          result = nil

          rails_controller_rescue do
            rails_controller_callbacks do
              result = catch(:halt) { yield }
            end
          end

          result = handle_rails_controller_response(result)

          throw :halt, result if result
        end

        # Runs any #(before|around|after)_action controller callbacks.
        def rails_controller_callbacks(&block)
          rails_controller_instance.run_callbacks(:process_action, &block)
        end

        # Runs any registered #rescue_from controller handlers.
        def rails_controller_rescue
          yield
        rescue Exception => exception
          rails_controller_instance.rescue_with_handler(exception) || raise

          unless rails_controller_instance.performed?
            raise Rodauth::Rails::Error, "rescue_from handler didn't write any response"
          end
        end

        # Handles controller rendering a response or setting response headers.
        def handle_rails_controller_response(result)
          if rails_controller_instance.performed?
            rails_controller_response
          elsif result
            result[1].merge!(rails_controller_instance.response.headers)
            result
          end
        end

        # Returns Roda response from controller response if set.
        def rails_controller_response
          controller_response = rails_controller_instance.response

          response.status = controller_response.status
          response.headers.merge! controller_response.headers
          response.write controller_response.body

          response.finish
        end
      end
    end
  end
end
