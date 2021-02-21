require "test_helper"

Rails.application.load_tasks

class RakeTest < ActiveSupport::TestCase
  test "rodauth:routes prints routes" do
    stdout, _ = capture_io do
      Rake::Task["rodauth:routes"].invoke
    end

    assert_equal <<~EOS, stdout
      Routes handled by RodauthApp:

        /login                   rodauth.login_path
        /create-account          rodauth.create_account_path
        /verify-account-resend   rodauth.verify_account_resend_path
        /verify-account          rodauth.verify_account_path
        /remember                rodauth.remember_path
        /logout                  rodauth.logout_path
        /reset-password-request  rodauth.reset_password_request_path
        /reset-password          rodauth.reset_password_path
        /change-password         rodauth.change_password_path
        /change-login            rodauth.change_login_path
        /verify-login-change     rodauth.verify_login_change_path
        /close-account           rodauth.close_account_path
        /unlock-account-request  rodauth.unlock_account_request_path
        /unlock-account          rodauth.unlock_account_path
        /multifactor-manage      rodauth.two_factor_manage_path
        /multifactor-auth        rodauth.two_factor_auth_path
        /multifactor-disable     rodauth.two_factor_disable_path
        /recovery-auth           rodauth.recovery_auth_path
        /recovery-codes          rodauth.recovery_codes_path

        /json/login                  rodauth(:json).login_path
        /json/create-account         rodauth(:json).create_account_path
        /json/verify-account-resend  rodauth(:json).verify_account_resend_path
        /json/verify-account         rodauth(:json).verify_account_path
    EOS
  end
end
