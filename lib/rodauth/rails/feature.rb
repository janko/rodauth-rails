module Rodauth
  Feature.define(:rails) do
    depends :email_base

    auth_methods(
      :rails_render,
      :rails_renderer,
      :rails_csrf_tag,
      :rails_csrf_param,
      :rails_csrf_token,
      :rails_check_csrf!,
      :rails_controller_instance,
      :rails_controller,
    )

    def view(page, title)
      rails_render page.tr("-", "_")
    rescue ActionView::MissingTemplate
      rails_render html: super.html_safe
    end

    def render(page)
      rails_render partial: page.tr("-", "_")
    rescue ActionView::MissingTemplate
      super
    end

    def csrf_tag(*)
      rails_csrf_tag
    end

    def hmac_secret
      ::Rails.application.secrets.secret_key_base
    end

    def flash_error_key
      :alert
    end

    private

    def before_rodauth
      rails_check_csrf!
      super
    end

    def create_email_to(to, subject, body)
      Mailer.create(to: to, from: email_from, subject: "#{email_subject_prefix}#{subject}", body: body)
    end

    def send_email(email)
      email.deliver_now
    end

    def rails_render(*args)
      rails_renderer.render(*args)
    end

    def rails_renderer
      ActionController::Renderer.new(rails_controller, scope.env, {})
    end

    def rails_csrf_tag
      %(<input type="hidden" name="#{rails_csrf_param}" value="#{rails_csrf_token}">)
    end

    def rails_csrf_param
      rails_controller.request_forgery_protection_token
    end

    def rails_csrf_token
      rails_controller_instance.send(:form_authenticity_token)
    end

    def rails_check_csrf!
      rails_controller_instance.send(:verify_authenticity_token)
    end

    def rails_controller_instance
      controller = rails_controller.new
      controller.set_request! ActionDispatch::Request.new(scope.env)
      controller
    end

    def rails_controller
      ApplicationController
    end

    # ActionMailer subclass to correctly wrap email delivering.
    class Mailer < ActionMailer::Base
      def create(**options)
        mail(**options)
      end
    end
  end

  # assign feature and feature configuration to constants for introspection
  Rails::Feature              = FEATURES[:rails]
  Rails::FeatureConfiguration = FEATURES[:rails].configuration
end
