module Rodauth
  module Rails
    class Mailer < ActionMailer::Base
      def create_email(options)
        mail(options)
      end
    end
  end
end
