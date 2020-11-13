require "test_helper"

Rails.application.load_tasks

class RakeTest < ActiveSupport::TestCase
  test "rodauth:routes prints routes" do
    stdout, _ = capture_io do
      Rake::Task["rodauth:routes"].invoke
    end

    assert_equal <<~EOS, stdout.strip + "\n"
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
    EOS
  end
end
