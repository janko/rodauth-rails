require "test_helper"

class RenderTest < IntegrationTest
  test "built-in Rodauth templates" do
    visit "/login"

    assert_includes page.html, %(id="login-form")
    assert_includes page.html, %(name="login")
    assert_includes page.html, %(name="password")

    assert_includes page.html, %(<title>Rodauth::Rails Test</title>)
  end

  test "built-in Rodauth templates with halting" do
    register(verify: true)
    logout

    login(password: "invalid")
    login(password: "invalid")
    login(password: "invalid")
    login(password: "invalid")

    assert_includes page.html, %(id="unlock-account-request-form")
    assert_includes page.html, %(<title>Rodauth::Rails Test</title>)
  end

  test "custom views" do
    register

    email = ActionMailer::Base.deliveries.last
    verify_account_link = email.body.to_s[%r{/verify-account\S+}]

    visit verify_account_link

    assert_includes page.html, %(id="custom-verify-account-form")

    assert_includes page.html, %(<title>Rodauth::Rails Test</title>)
  end

  test "custom views as partials" do
    register(login: "user@example.com", password: "secret", verify: true)
    logout

    visit "/login"
    fill_in "Login", with: "user@example.com"
    fill_in "Password", with: "invalid"
    click_on "Login"

    assert_equal "/login", current_path

    assert_includes page.html, %(id="custom-reset-password-request-form")

    assert_equal 1, page.html.scan(%(<title>Rodauth::Rails Test</title>)).count
  end

  test "custom partials" do
    visit "/logout"

    assert_includes page.html, %(id="logout-form")
    assert_includes page.html, %(id="custom-global-logout")

    assert_equal 1, page.html.scan(%(<title>Rodauth::Rails Test</title>)).count
  end
end
