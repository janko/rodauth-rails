require "test_helper"

class RenderTest < IntegrationTest
  test "built-in Rodauth views" do
    visit "/login"

    assert_includes page.html, %(id="login-form")
    assert_includes page.html, %(name="login")
    assert_includes page.html, %(name="password")

    assert_includes page.html, %(<title>Login</title>)
  end

  test "built-in Rodauth views with halting" do
    register(verify: true)
    logout

    4.times { login(password: "invalid") }

    assert_includes page.html, %(id="unlock-account-request-form")
    assert_includes page.html, %(<title>Request Account Unlock</title>)
  end

  test "built-in Rodauth partials" do
    register
    visit "/close-account"

    assert_includes page.html, %(name="password")
    assert_includes page.html, %(type="submit")
  end

  test "custom views" do
    register

    email = ActionMailer::Base.deliveries.last
    verify_account_link = email.body.to_s[%r{/verify-account\S+}]

    visit verify_account_link

    assert_includes page.html, %(id="custom-verify-account-form")

    assert_includes page.html, %(<title>Verify Account</title>)
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

    assert_includes page.html, %(<title>Login</title>)
  end

  test "custom partials" do
    visit "/logout"

    assert_includes page.html, %(id="logout-form")
    assert_includes page.html, %(id="custom-global-logout")

    assert_includes page.html, %(<title>Logout</title>)
  end

  test "set title" do
    visit "/login"

    assert_includes page.html, %(<title>Login</title>)

    visit "/admin/login"

    assert_includes page.html, %(<title>Rodauth::Rails Test</title>)
  end

  test "disabling turbo for built-in templates" do
    Account.create!(email: "user@example.com", password: "secret123", status: "verified")

    visit "/verify-account-resend"
    assert_includes page.html, %(<form action="/verify-account-resend" method="post" class="rodauth" role="form" id="verify-account-resend-form" data-turbo="false">)

    visit "/login"
    assert_includes page.html, %(<form method="post" class="rodauth" role="form" id="login-form" data-turbo="false">)

    fill_in "Login", with: "user@example.com"
    fill_in "Password", with: "wrongsecret"
    click_on "Login"
    assert_includes page.html, %(<form id="custom-reset-password-request-form" action="/reset-password-request" accept-charset="UTF-8" method="post" data-turbo="false">)
  end

  test "rendering built-in templates with alternative formats" do
    page.driver.browser.get "/login", {}, { "HTTP_ACCEPT" => "text/vnd.turbo-stream.html, text/html" }

    assert_includes page.html, "Login"
  end if defined?(::Turbo)

  test "rendering turbo streams" do
    register(login: "user@example.com")

    page.driver.browser.post "/login",
      { login: "user@example.com" },
      { "HTTP_ACCEPT" => "text/vnd.turbo-stream.html, text/html" }

    assert_equal %(<turbo-stream action="append" target="login-form"><template><div id="turbo-stream">login failed</div></template></turbo-stream>), page.html
  end if defined?(::Turbo)

  test "path format is preserved with basic auth" do
    Account.create!(email: "user@example.com", password: "secret123", status: "verified")
    page.driver.browser.basic_authorize "user@example.com", "secret123"

    page.driver.browser.get "/basic_auth", {}, { "HTTP_ACCEPT" => "*/*" }
    assert_equal "Basic Auth", page.html
    assert_equal "text/plain; charset=utf-8", page.response_headers["Content-Type"]

    page.driver.browser.get "/basic_auth.json", {}, { "HTTP_ACCEPT" => "*/*" }
    assert_equal "{\"message\":\"Basic Auth\"}", page.html
    assert_equal "application/json; charset=utf-8", page.response_headers["Content-Type"]

    page.driver.browser.header "Authorization", nil
  end
end
