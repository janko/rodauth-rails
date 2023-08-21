require "test_helper"

Rails.application.load_tasks

class RakeTest < ActiveSupport::TestCase
  test "rodauth:routes prints routes" do
    stdout, _ = capture_io do
      Rake::Task["rodauth:routes"].invoke
    end

    expected_output = <<~EOS
      Routes handled by RodauthApp:

        GET|POST  /login                   rodauth.login_path
        GET|POST  /create-account          rodauth.create_account_path
        GET|POST  /verify-account-resend   rodauth.verify_account_resend_path
        GET|POST  /verify-account          rodauth.verify_account_path
        GET|POST  /remember                rodauth.remember_path
        GET|POST  /logout                  rodauth.logout_path
        GET|POST  /reset-password-request  rodauth.reset_password_request_path
        GET|POST  /reset-password          rodauth.reset_password_path
        GET|POST  /change-password         rodauth.change_password_path
        GET|POST  /change-login            rodauth.change_login_path
        GET|POST  /close-account           rodauth.close_account_path
        POST      /unlock-account-request  rodauth.unlock_account_request_path
        GET|POST  /unlock-account          rodauth.unlock_account_path
        GET       /multifactor-manage      rodauth.two_factor_manage_path
        GET       /multifactor-auth        rodauth.two_factor_auth_path
        GET|POST  /multifactor-disable     rodauth.two_factor_disable_path
        GET|POST  /recovery-auth           rodauth.recovery_auth_path
        GET|POST  /recovery-codes          rodauth.recovery_codes_path

        GET|POST  /admin/login                rodauth(:admin).login_path
        GET       /admin/multifactor-manage   rodauth(:admin).two_factor_manage_path
        GET       /admin/multifactor-auth     rodauth(:admin).two_factor_auth_path
        GET|POST  /admin/multifactor-disable  rodauth(:admin).two_factor_disable_path
        GET|POST  /admin/webauthn-auth        rodauth(:admin).webauthn_auth_path
        GET|POST  /admin/webauthn-setup       rodauth(:admin).webauthn_setup_path
        GET|POST  /admin/webauthn-remove      rodauth(:admin).webauthn_remove_path
        POST      /admin/webauthn-login       rodauth(:admin).webauthn_login_path

        POST  /jwt/login                  rodauth(:jwt).login_path
        POST  /jwt/create-account         rodauth(:jwt).create_account_path
        POST  /jwt/verify-account-resend  rodauth(:jwt).verify_account_resend_path
        POST  /jwt/verify-account         rodauth(:jwt).verify_account_path

        POST  /json/login                  rodauth(:json).login_path
        POST  /json/create-account         rodauth(:json).create_account_path
        POST  /json/verify-account-resend  rodauth(:json).verify_account_resend_path
        POST  /json/verify-account         rodauth(:json).verify_account_path
        POST  /json/multifactor-manage     rodauth(:json).two_factor_manage_path
        POST  /json/multifactor-auth       rodauth(:json).two_factor_auth_path
        POST  /json/multifactor-disable    rodauth(:json).two_factor_disable_path
    EOS

    if RUBY_ENGINE == "jruby"
      expected_output.gsub!(/^.+webauthn.+$\n/, "")
    end

    assert_equal expected_output, stdout
  end
end
