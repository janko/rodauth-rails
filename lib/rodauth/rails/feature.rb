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
        super.html_safe
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

    def button(*)
      super.html_safe
    end

    delegate :rails_routes, :rails_request, to: :scope

    private

    # Runs controller callbacks and rescue handlers around Rodauth actions.
    def _around_rodauth(&block)
      result = nil

      rails_instrument_request do
        rails_controller_rescue do
          rails_controller_callbacks do
            result = catch(:halt) { super(&block) }
          end
        end

        result = handle_rails_controller_response(result)
      end

      throw :halt, result if result
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

    # Runs any #(before|around|after)_action controller callbacks.
    def rails_controller_callbacks
      # don't verify CSRF token as part of callbacks, Rodauth will do that
      rails_controller_forgery_protection { false }

      rails_controller_instance.run_callbacks(:process_action) do
        # turn the setting back to default so that form tags generate CSRF tags
        rails_controller_forgery_protection { rails_controller.allow_forgery_protection }

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

    def rails_instrument_request
      request = rails_request

      raw_payload = {
        controller: scope.class.superclass.name,
        action: "call",
        request: request,
        params: request.filtered_parameters,
        headers: request.headers,
        format: request.format.ref,
        method: request.request_method,
        path: request.fullpath
      }

      ActiveSupport::Notifications.instrument("start_processing.action_controller", raw_payload)

      ActiveSupport::Notifications.instrument("process_action.action_controller", raw_payload) do |payload|
        begin
          result = yield
          response = ActionDispatch::Response.new *(result || [404, {}, []])

          rails_instrument_redirection(request, response) if [301, 302].include?(response.status)

          payload[:response] = response
          payload[:status] = response.status
        rescue => error
          payload[:status] = ActionDispatch::ExceptionWrapper.status_code_for_exception(error.class.name)
          raise
        ensure
          rails_controller_eval { append_info_to_payload(payload) }
        end
      end
    end

    def rails_instrument_redirection(request, response)
      payload = { request: request, status: response.status, location: response.filtered_location }
      ActiveSupport::Notifications.instrument("redirect_to.action_controller", payload)
    end

    # Returns Roda response from controller response if set.
    def rails_controller_response
      controller_response = rails_controller_instance.response

      response.status = controller_response.status
      response.headers.merge! controller_response.headers
      response.write controller_response.body

      response.finish
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
      return if rails_api_controller?

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

    # allows/disables forgery protection
    def rails_controller_forgery_protection(&value)
      return if rails_api_controller?

      rails_controller_instance.allow_forgery_protection = value.call
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

    def rails_controller
      if only_json? && Rodauth::Rails.api_only?
        ActionController::API
      else
        ActionController::Base
      end
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
