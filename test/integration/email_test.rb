require "test_helper"

class EmailTest < IntegrationTest
  test "mailer delivery" do
    register(login: "user@example.com")

    assert_equal 1, ActionMailer::Base.deliveries.count

    email = ActionMailer::Base.deliveries[0]

    assert_equal "user@example.com",             email[:to].to_s
    assert_equal "noreply@rodauth.test",         email[:from].to_s
    assert_equal "[RodauthTest] Verify Account", email[:subject].to_s

    assert_includes email.body.to_s, "Someone has created an account with this email address"
  end

  test "verify login change email" do
    register(login: "user@example.com", password: "secret", verify: true)

    visit "/change-login"

    fill_in "Login", with: "new@example.com"
    fill_in "Password", with: "secret"
    click_on "Change Login"

    assert_equal 2, ActionMailer::Base.deliveries.count
  end
end
