module Rodauth
  module Rails
    module Feature
      module Instrumentation
        extend ActiveSupport::Concern

        private

        def _around_rodauth
          rails_instrument_request { super }
        end

        def redirect(*)
          rails_instrument_redirection { super }
        ensure
          request.env["rodauth.rails.status"] = response.status
        end

        def return_response(*)
          super
        ensure
          request.env["rodauth.rails.status"] = response.status
        end

        def rails_render(*)
          render_output = nil
          rails_controller_instance.view_runtime = rails_controller_instance.send(:cleanup_view_runtime) do
            rails_benchmark { render_output = super }
          end
          render_output
        end

        def rails_instrument_request
          request = rails_request

          raw_payload = {
            controller: rails_controller.name,
            action: current_route.to_s,
            request: request,
            params: request.filtered_parameters,
            headers: request.headers,
            format: request.format.ref,
            method: request.request_method,
            path: request.fullpath
          }

          ActiveSupport::Notifications.instrument("start_processing.action_controller", raw_payload)

          ActiveSupport::Notifications.instrument("process_action.action_controller", raw_payload) do |payload|
            result = catch(:halt) { yield }

            rails_response = build_rails_response(result || [404, {}, []])
            payload[:response] = rails_response
            payload[:status] = rails_response.status

            throw :halt, result if result
          rescue => error
            payload[:status] = ActionDispatch::ExceptionWrapper.status_code_for_exception(error.class.name)
            raise
          ensure
            rails_controller_eval { append_info_to_payload(payload) }
          end
        end

        def rails_instrument_redirection
          ActiveSupport::Notifications.instrument("redirect_to.action_controller", request: rails_request) do |payload|
            result = catch(:halt) { yield }

            rails_response = build_rails_response(result)
            payload[:status] = rails_response.status
            payload[:location] = rails_response.filtered_location

            throw :halt, result
          end
        end

        def build_rails_response(args)
          response = ActionDispatch::Response.new(*args)
          response.request = rails_request
          response
        end

        if ActionPack.version >= Gem::Version.new("8.0")
          def rails_benchmark(&block)
            ActiveSupport::Benchmark.realtime(:float_millisecond, &block)
          end
        else
          def rails_benchmark(&block)
            Benchmark.ms(&block)
          end
        end
      end
    end
  end
end
