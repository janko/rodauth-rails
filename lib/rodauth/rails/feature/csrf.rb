module Rodauth
  module Rails
    module Feature
      module Csrf
        extend ActiveSupport::Concern

        included do
          auth_methods(
            :rails_csrf_tag,
            :rails_csrf_param,
            :rails_csrf_token,
            :rails_check_csrf!,
          )
        end

        # Render Rails CSRF tags in Rodauth templates.
        def csrf_tag(*)
          rails_csrf_tag if rails_controller_csrf?
        end

        # Verify Rails' authenticity token.
        def check_csrf
          rails_check_csrf! if rails_controller_csrf?
        end

        # Have Rodauth call #check_csrf automatically.
        def check_csrf?
          rails_check_csrf? if rails_controller_csrf?
        end

        private

        def rails_controller_callbacks
          return super unless rails_controller_csrf?

          # don't verify CSRF token as part of callbacks, Rodauth will do that
          rails_controller_instance.allow_forgery_protection = false
          super do
            # turn the setting back to default so that form tags generate CSRF tags
            rails_controller_instance.allow_forgery_protection = rails_controller.allow_forgery_protection
            yield
          end
        end

        # Checks whether ActionController::RequestForgeryProtection is included
        # and that protect_from_forgery was called.
        def rails_check_csrf?
          !!rails_controller_instance.forgery_protection_strategy
        end

        # Calls the controller to verify the authenticity token.
        def rails_check_csrf!
          rails_controller_instance.send(:verify_authenticity_token)
        end

        # Hidden tag with Rails CSRF token inserted into Rodauth templates.
        def rails_csrf_tag
          %(<input type="hidden" name="#{rails_csrf_param}" value="#{rails_csrf_token}">)
        end

        # The request parameter under which to send the Rails CSRF token.
        def rails_csrf_param
          rails_controller.request_forgery_protection_token
        end

        # The Rails CSRF token value inserted into Rodauth templates.
        def rails_csrf_token
          rails_controller_instance.send(:form_authenticity_token)
        end

        # Checks whether ActionController::RequestForgeryProtection is included.
        def rails_controller_csrf?
          rails_controller.respond_to?(:protect_from_forgery)
        end
      end
    end
  end
end
