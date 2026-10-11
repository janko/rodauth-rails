require "test_helper"

class CsrfTest < IntegrationTest
  test "built-in templates include CSRF token" do
    visit "/login"

    assert_match %r(<input type="hidden" name="authenticity_token" value="\S+">), page.html
  end

  test "custom templates include CSRF token" do
    visit "/reset-password-request"

    assert_match %r(<input type="hidden" name="authenticity_token" value="\S+"( autocomplete="off")? />), page.html
  end

  test "rodauth actions verify CSRF token" do
    assert_raises ActionController::InvalidAuthenticityToken do
      page.driver.browser.post "/login", {
        "login" => "user@example.com",
        "password" => "secret"
      }, { "HTTP_SEC_FETCH_SITE" => "none" }
    end
  end

  test "rodauth actions reject cross-site requests" do
    assert_raises ActionController::InvalidAuthenticityToken do
      page.driver.browser.post "/login", {
        "login" => "user@example.com",
        "password" => "secret"
      }, { "HTTP_SEC_FETCH_SITE" => "cross-site" }
    end
  end
end
