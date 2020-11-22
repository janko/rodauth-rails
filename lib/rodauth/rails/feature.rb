module Rodauth
  Feature.define(:rails) do
    depends :email_base

    # List of overridable methods.
    auth_methods(
      :rails_render,
      :rails_csrf_tag,
      :rails_csrf_param,
      :rails_csrf_token,
      :rails_check_csrf!,
      :rails_controller,
    )

    auth_cached_method :rails_controller_instance

    # Renders templates with layout. First tries to render a user-defined
    # template, otherwise falls back to Rodauth's template.
    def view(page, *)
      rails_render(action: page.tr("-", "_"), layout: true) ||
        rails_render(html: super.html_safe, layout: true)
    end

    # Renders templates without layout. First tries to render a user-defined
    # template or partial, otherwise falls back to Rodauth's template.
    def render(page)
      rails_render(partial: page.tr("-", "_"), layout: false) ||
        rails_render(action: page.tr("-", "_"), layout: false) ||
        super
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

    # Default the flash error key to Rails' default :alert.
    def flash_error_key
      :alert
    end

    private

    # Runs controller callbacks and rescue handlers around Rodauth actions.
    def _around_rodauth(&block)
      result = nil

      rails_controller_rescue do
        rails_controller_callbacks do
          result = catch(:halt) { super(&block) }
        end
      end

      if rails_controller_instance.performed?
        rails_controller_response
      else
        result[1].merge!(rails_controller_instance.response.headers)
        throw :halt, result
      end
    end

    # Runs any #(before|around|after)_action controller callbacks.
    def rails_controller_callbacks
      # don't verify CSRF token as part of callbacks, Rodauth will do that
      rails_controller_instance.allow_forgery_protection = false

      rails_controller_instance.run_callbacks(:process_action) do
        # turn the setting back to default so that form tags generate CSRF tags
        rails_controller_instance.allow_forgery_protection = rails_controller.allow_forgery_protection

        yield
      end
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

    # Returns Roda response from controller response if set.
    def rails_controller_response
      controller_response = rails_controller_instance.response

      response.status = controller_response.status
      response.headers.merge! controller_response.headers
      response.write controller_response.body

      request.halt
    end

    # Create emails with ActionMailer which uses configured delivery method.
    def create_email_to(to, subject, body)
      Mailer.create_email(to: to, from: email_from, subject: "#{email_subject_prefix}#{subject}", body: body)
    end

    # Delivers the given email.
    def send_email(email)
      email.deliver_now
    end

    # Calls the Rails renderer, returning nil if a template is missing.
    def rails_render(*args)
      return if only_json?

      rails_controller_instance.render_to_string(*args)
    rescue ActionView::MissingTemplate
      nil
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

    # Instances of the configured controller with current request's env hash.
    def _rails_controller_instance
      request  = ActionDispatch::Request.new(scope.env)
      instance = rails_controller.new

      if ActionPack.version >= Gem::Version.new("5.0")
        instance.set_request! request
        instance.set_response! rails_controller.make_response!(request)
      else
        instance.send(:set_response!, request)
        instance.instance_variable_set(:@_request, request)
      end

      instance
    end

    # Controller class to use for rendering and CSRF protection.
    def rails_controller
      ActionController::Base
    end

    # ActionMailer subclass for correct email delivering.
    class Mailer < ActionMailer::Base
      def create_email(**options)
        mail(**options)
      end
    end
  end

  # Assign feature and feature configuration to constants for introspection.
  Rails::Feature              = FEATURES[:rails]
  Rails::FeatureConfiguration = FEATURES[:rails].configuration
end
