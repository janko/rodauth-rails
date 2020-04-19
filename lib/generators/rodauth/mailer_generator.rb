require "rails/generators/base"

module Rodauth
  module Rails
    module Generators
      class MailerGenerator < ::Rails::Generators::Base
        source_root "#{__dir__}/templates"
        namespace "rodauth:mailer"

        def copy_mailer
          template "app/mailers/rodauth_mailer.rb"
        end

        def copy_mailer_views
          directory "app/views/rodauth_mailer"
        end
      end
    end
  end
end
