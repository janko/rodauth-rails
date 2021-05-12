module Rodauth
  module Rails
    module Feature
      module Csrf
        def self.included(feature)
          feature.auth_methods(
            :rails_csrf_tag,
            :rails_csrf_param,
            :rails_csrf_token,
            :rails_check_csrf!,
          )
        end

        # Render Rails CSRF tags in Rodauth templates.
        def csrf_tag(*)
          rails_csrf_tag
        end

        # Verify Rails' authenticity token.
        def check_csrf
          rails_check_csrf!
        end

        # Have Rodauth call #check_csrf automatically.
        def check_csrf?
          true
        end

        private

        def rails_controller_callbacks
          return super if rails_api_controller?

          # don't verify CSRF token as part of callbacks, Rodauth will do that
          rails_controller_instance.allow_forgery_protection = false
          super do
            # turn the setting back to default so that form tags generate CSRF tags
            rails_controller_instance.allow_forgery_protection = rails_controller.allow_forgery_protection
            yield
          end
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
      end
    end
  end
end
