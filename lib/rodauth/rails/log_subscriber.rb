module Rodauth
  module Rails
    class LogSubscriber < ActiveSupport::LogSubscriber
      def start_processing(event)
        rodauth = event.payload[:rodauth]
        app_class = rodauth.scope.class.superclass
        format = rodauth.rails_request.format.ref
        format = format.to_s.upcase if format.is_a?(Symbol)
        format = "*/*" if format.nil?

        info "Processing by #{app_class} as #{format}"
      end

      def process_request(event)
        status = event.payload[:status]

        additions = ActionController::Base.log_process_action(event.payload)
        if ::Rails.gem_version >= Gem::Version.new("6.0")
          additions << "Allocations: #{event.allocations}"
        end

        message = "Completed #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]} in #{event.duration.round}ms"
        message << " (#{additions.join(" | ")})"
        message << "\n\n" if defined?(::Rails.env) && ::Rails.env.development?

        info message
      end

      def logger
        ::Rails.logger
      end
    end
  end
end
