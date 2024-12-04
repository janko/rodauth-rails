require "rails/generators/base"

module Rodauth
  module Rails
    module Generators
      class MailerGenerator < ::Rails::Generators::Base
        source_root "#{__dir__}/templates"
        namespace "rodauth:mailer"

        argument :selected_features, optional: true, type: :array,
          desc: "Rodauth features to generate mailer integration for (verify_account, verify_login_change, reset_password etc.)"

        class_option :all, aliases: "-a", type: :boolean,
          desc: "Generates mailer integration for all Rodauth features",
          default: false

        class_option :name, aliases: "-n", type: :string,
          desc: "The configuration name for which to generate mailer configuration",
          default: nil

        EMAILS = {
          verify_account:         %w[verify_account],
          reset_password:         %w[reset_password],
          verify_login_change:    %w[verify_login_change],
          email_auth:             %w[email_auth],
          lockout:                %w[unlock_account],
          reset_password_notify:  %w[reset_password_notify],
          change_password_notify: %w[password_changed],
          otp_modify_email:       %w[otp_setup otp_disabled],
          otp_lockout_email:      %w[otp_locked_out otp_unlocked otp_unlock_failed],
          webauthn_modify_email:  %w[webauthn_authenticator_added webauthn_authenticator_removed],
        }

        TOKENS = %w[reset_password verify_account verify_login_change email_auth unlock_account]

        def copy_mailer_views
          return unless validate_features

          emails.each do |email|
            copy_file "app/views/rodauth_mailer/#{email}.text.erb"
          end
        end

        def copy_mailer
          return unless validate_features

          if File.exist?("#{destination_root}/app/mailers/rodauth_mailer.rb") && options.fetch(:skip, true) && !options[:force] && behavior == :invoke
            say "\nCopy the following lines into your Rodauth mailer:\n\n#{mailer_content}"
          else
            template "app/mailers/rodauth_mailer.rb"
          end
        end

        def show_configuration
          return unless behavior == :invoke && validate_features

          say "\nCopy the following lines into your Rodauth configuration:\n\n#{configuration_content}"
        end

        private

        def mailer_content
          emails
            .map { |email| File.read("#{__dir__}/mailer/#{email}.erb") }
            .map { |content| erb_eval(content) }
            .join("\n")
            .indent(2)
        end

        def configuration_content
          emails
            .map { |email| configuration_chunk(email) }
            .join
            .indent(2)
        end

        def configuration_chunk(email)
          <<~RUBY
            create_#{email}_email do#{" |_login|" if email == "verify_login_change"}
              RodauthMailer.#{email}(self.class.configuration_name, account_id#{", #{email}_key_value" if TOKENS.include?(email)})
            end
          RUBY
        end

        def erb_eval(content)
          ERB.new(content, trim_mode: "-").result(binding)
        end

        def emails
          features.flat_map { |feature| EMAILS.fetch(feature) }
        end

        def validate_features
          if (features - EMAILS.keys).any?
            say "No available email template for feature(s): #{(features - EMAILS.keys).join(", ")}", :error
            false
          else
            true
          end
        end

        def features
          if options[:all]
            EMAILS.keys
          elsif selected_features
            selected_features.map(&:to_sym)
          else
            rodauth_configuration.features & EMAILS.keys
          end
        end

        def rodauth_configuration
          Rodauth::Rails.app.rodauth!(configuration_name)
        end

        def configuration_name
          options[:name]&.to_sym
        end
      end
    end
  end
end
