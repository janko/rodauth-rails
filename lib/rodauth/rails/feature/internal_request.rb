module Rodauth
  module Rails
    module Feature
      module InternalRequest
        extend ActiveSupport::Concern

        included do
          auth_private_methods :rails_url_options
        end

        def domain
          return super unless missing_host? && rails_url_options!

          rails_url_options.fetch(:host)
        end

        def base_url
          return super unless missing_host? && domain && rails_url_options!

          scheme = rails_url_options[:protocol] || "http"
          port = rails_url_options[:port]

          url = "#{scheme}://#{domain}"
          url << ":#{port}" if port
          url
        end

        def rails_url_options
          return _rails_url_options if frozen? # handle path_class_methods feature
          @rails_url_options ||= _rails_url_options
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
          internal_request? && (request.host.nil? || request.host == INVALID_DOMAIN) || scope.nil?
        end

        def rails_url_options!
          rails_url_options.presence or fail Error, "There is no information to set the URL host from. Please set config.action_mailer.default_url_options in your Rails application, configure #domain and #base_url in your Rodauth configuration, or set #rails_url_options on the Rodauth instance."
        end

        def _rails_url_options
          defined?(ActionMailer) ? ActionMailer::Base.default_url_options.dup : {}
        end
      end
    end
  end
end
