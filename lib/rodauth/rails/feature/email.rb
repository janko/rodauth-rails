module Rodauth
  module Rails
    module Feature
      module Email
        extend ActiveSupport::Concern

        included do
          depends :email_base
        end

        private

        # Create emails with ActionMailer which uses configured delivery method.
        def create_email_to(to, subject, body)
          Rodauth::Rails::Mailer.create_email(
            to: to,
            from: email_from,
            subject: "#{email_subject_prefix}#{subject}",
            body: body
          )
        end

        # Delivers the given email.
        def send_email(email)
          email.deliver_now
        end

        # for backwards compatibility
        Mailer = Rodauth::Rails::Mailer
        deprecate_constant :Mailer
      end
    end
  end
end
