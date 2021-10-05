module Rodauth
  module Rails
    module Feature
      module InternalRequest
        def domain
          return super unless missing_host?

          Rodauth::Rails.url_options[:host]
        end

        def base_url
          return super unless missing_host? && domain

          url_options = Rodauth::Rails.url_options

          url = "#{url_options[:protocol]}://#{domain}"
          url << ":#{url_options[:port]}" if url_options[:port]
          url
        end

        private

        def rails_controller_around
          return yield if internal_request?
          super
        end

        def rails_instrument_request
          return yield if internal_request?
          super
        end

        def rails_instrument_redirection
          return yield if internal_request?
          super
        end

        # Checks whether we're in an internal request and host was not set,
        # or the request doesn't exist such as with path_class_methods feature.
        def missing_host?
          internal_request? && request.host == INVALID_DOMAIN || scope.nil?
        end
      end
    end
  end
end
