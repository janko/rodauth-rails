require "test_helper"
require "generators/rodauth/mailer_generator"

class MailerGeneratorTest < Rails::Generators::TestCase
  tests Rodauth::Rails::Generators::MailerGenerator
  destination File.expand_path("#{__dir__}/../../tmp")
  setup :prepare_destination

  test "default features" do
    output = run_generator

    %w[verify_account reset_password verify_login_change unlock_account].each do |template|
      assert_file "app/views/rodauth_mailer/#{template}.text.erb"
    end
    assert_no_file "app/views/rodauth_mailer/email_auth.text.erb"

    assert_file "app/mailers/rodauth_mailer.rb", <<~RUBY
      class RodauthMailer < ApplicationMailer
        default to: -> { @rodauth.email_to }, from: -> { @rodauth.email_from }

        def verify_account(name, account_id, key)
          @rodauth = rodauth(name, account_id) { @verify_account_key_value = key }
          @account = @rodauth.rails_account

          mail subject: @rodauth.email_subject_prefix + @rodauth.verify_account_email_subject
        end

        def reset_password(name, account_id, key)
          @rodauth = rodauth(name, account_id) { @reset_password_key_value = key }
          @account = @rodauth.rails_account

          mail subject: @rodauth.email_subject_prefix + @rodauth.reset_password_email_subject
        end

        def verify_login_change(name, account_id, key)
          @rodauth = rodauth(name, account_id) { @verify_login_change_key_value = key }
          @account = @rodauth.rails_account
          @new_email = @account.login_change_key.login

          mail to: @new_email, subject: @rodauth.email_subject_prefix + @rodauth.verify_login_change_email_subject
        end

        def unlock_account(name, account_id, key)
          @rodauth = rodauth(name, account_id) { @unlock_account_key_value = key }
          @account = @rodauth.rails_account

          mail subject: @rodauth.email_subject_prefix + @rodauth.unlock_account_email_subject
        end

        private

        # Default URL options are inherited from Action Mailer, but you can override them
        # ad-hoc by modifying the `rodauth.rails_url_options` hash.
        def rodauth(name, account_id, &block)
          instance = RodauthApp.rodauth(name).allocate
          instance.account_from_id(account_id)
          instance.instance_eval(&block) if block
          instance
        end
      end
    RUBY

    assert_includes output, <<~EOS
      Copy the following lines into your Rodauth configuration:

        create_verify_account_email do
          RodauthMailer.verify_account(self.class.configuration_name, account_id, verify_account_key_value)
        end
        create_reset_password_email do
          RodauthMailer.reset_password(self.class.configuration_name, account_id, reset_password_key_value)
        end
        create_verify_login_change_email do |_login|
          RodauthMailer.verify_login_change(self.class.configuration_name, account_id, verify_login_change_key_value)
        end
        create_unlock_account_email do
          RodauthMailer.unlock_account(self.class.configuration_name, account_id, unlock_account_key_value)
        end
    EOS
  end

  test "specified features" do
    output = run_generator %w[webauthn_modify_email]

    assert_file "app/views/rodauth_mailer/webauthn_authenticator_added.text.erb"
    assert_file "app/views/rodauth_mailer/webauthn_authenticator_removed.text.erb"
    assert_no_file "app/views/rodauth_mailer/reset_password.text.erb"

    assert_file "app/mailers/rodauth_mailer.rb", /def webauthn_authenticator_added/
    assert_file "app/mailers/rodauth_mailer.rb", /def webauthn_authenticator_removed/

    assert_match(/create_webauthn_authenticator_added_email/, output)
    assert_match(/create_webauthn_authenticator_removed_email/, output)
  end

  test "additional features" do
    run_generator
    output = run_generator %w[email_auth]

    assert_file "app/mailers/rodauth_mailer.rb", /def verify_account/

    assert_includes output, <<~EOS
      Copy the following lines into your Rodauth mailer:

        def email_auth(name, account_id, key)
          @rodauth = rodauth(name, account_id) { @email_auth_key_value = key }
          @account = @rodauth.rails_account

          mail subject: @rodauth.email_subject_prefix + @rodauth.email_auth_email_subject
        end
    EOS
  end

  test "all features" do
    output = run_generator %w[--all]

    templates = %w[otp_setup otp_disabled otp_locked_out otp_unlocked otp_unlock_failed]
    templates.each do |template|
      assert_file "app/views/rodauth_mailer/#{template}.text.erb"
      assert_file "app/mailers/rodauth_mailer.rb", /def #{template}/
      assert_includes output, "create_#{template}_email do"
    end
  end

  test "secondary configuration" do
    run_generator %w[--name admin]

    unless RUBY_ENGINE == "jruby"
      assert_file "app/views/rodauth_mailer/webauthn_authenticator_added.text.erb"
      assert_file "app/views/rodauth_mailer/webauthn_authenticator_removed.text.erb"
    end
  end

  test "unknown features" do
    output = run_generator %w[nonexisting]

    assert_includes output, "No available email template for feature(s): nonexisting"
  end
end
