require "rails/generators/base"

module Rodauth
  module Rails
    module Generators
      class MailerGenerator < ::Rails::Generators::Base
        source_root "#{__dir__}/templates"
        namespace "rodauth:mailer"

        VIEWS = %w[
          email_auth
          password_changed
          reset_password
          unlock_account
          verify_account
          verify_login_change
        ]

        def copy_mailer
          template "app/mailers/rodauth_mailer.rb"
        end

        def copy_mailer_views
          VIEWS.each do |view|
            create_file "app/views/rodauth_mailer/#{view}.text.erb",
              File.read("#{__dir__}/templates/app/views/rodauth_mailer/#{view}.text.erb")
          end
        end
      end
    end
  end
end
