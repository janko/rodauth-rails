require "test_helper"

Rails.application.load_tasks

class RakeTest < ActiveSupport::TestCase
  test "rodauth:routes prints routes" do
    stdout, _ = capture_io do
      Rake::Task["rodauth:routes"].invoke
    end

    expected_output = <<~EOS
      Routes handled by RodauthApp:

                         login  GET|POST  /login                   rodauth.login_path
                create_account  GET|POST  /create-account          rodauth.create_account_path
         verify_account_resend  GET|POST  /verify-account-resend   rodauth.verify_account_resend_path
                verify_account  GET|POST  /verify-account          rodauth.verify_account_path
                      remember  GET|POST  /remember                rodauth.remember_path
                        logout  GET|POST  /logout                  rodauth.logout_path
        reset_password_request  GET|POST  /reset-password-request  rodauth.reset_password_request_path
                reset_password  GET|POST  /reset-password          rodauth.reset_password_path
               change_password  GET|POST  /change-password         rodauth.change_password_path
                  change_login  GET|POST  /change-login            rodauth.change_login_path
                 close_account  GET|POST  /close-account           rodauth.close_account_path
        unlock_account_request  POST      /unlock-account-request  rodauth.unlock_account_request_path
                unlock_account  GET|POST  /unlock-account          rodauth.unlock_account_path
             two_factor_manage  GET       /multifactor-manage      rodauth.two_factor_manage_path
               two_factor_auth  GET       /multifactor-auth        rodauth.two_factor_auth_path
            two_factor_disable  GET|POST  /multifactor-disable     rodauth.two_factor_disable_path
                 recovery_auth  GET|POST  /recovery-auth           rodauth.recovery_auth_path
                recovery_codes  GET|POST  /recovery-codes          rodauth.recovery_codes_path

                     login  GET|POST  /admin/login                rodauth(:admin).login_path
         two_factor_manage  GET       /admin/multifactor-manage   rodauth(:admin).two_factor_manage_path
           two_factor_auth  GET       /admin/multifactor-auth     rodauth(:admin).two_factor_auth_path
        two_factor_disable  GET|POST  /admin/multifactor-disable  rodauth(:admin).two_factor_disable_path
             webauthn_auth  GET|POST  /admin/webauthn-auth        rodauth(:admin).webauthn_auth_path
            webauthn_setup  GET|POST  /admin/webauthn-setup       rodauth(:admin).webauthn_setup_path
           webauthn_remove  GET|POST  /admin/webauthn-remove      rodauth(:admin).webauthn_remove_path
            webauthn_login  POST      /admin/webauthn-login       rodauth(:admin).webauthn_login_path

                        login  POST  /jwt/login                  rodauth(:jwt).login_path
               create_account  POST  /jwt/create-account         rodauth(:jwt).create_account_path
        verify_account_resend  POST  /jwt/verify-account-resend  rodauth(:jwt).verify_account_resend_path
               verify_account  POST  /jwt/verify-account         rodauth(:jwt).verify_account_path

                        login  POST  /json/login                  rodauth(:json).login_path
               create_account  POST  /json/create-account         rodauth(:json).create_account_path
        verify_account_resend  POST  /json/verify-account-resend  rodauth(:json).verify_account_resend_path
               verify_account  POST  /json/verify-account         rodauth(:json).verify_account_path
            two_factor_manage  POST  /json/multifactor-manage     rodauth(:json).two_factor_manage_path
              two_factor_auth  POST  /json/multifactor-auth       rodauth(:json).two_factor_auth_path
           two_factor_disable  POST  /json/multifactor-disable    rodauth(:json).two_factor_disable_path
    EOS

    if RUBY_ENGINE == "jruby"
      expected_output.gsub!(/^.+webauthn.+$\n/, "")
    end

    assert_equal expected_output, stdout
  end
end
