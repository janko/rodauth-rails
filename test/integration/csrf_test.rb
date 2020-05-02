require "test_helper"

class CsrfTest < IntegrationTest
  test "built-in templates include CSRF token" do
    visit "/login"

    assert_match %r(<input type="hidden" name="authenticity_token" value="\S+">), page.html
  end

  test "rodauth actions verify CSRF token" do
    assert_raises ActionController::InvalidAuthenticityToken do
      page.driver.browser.post "/login", params: {
        "login" => "user@example.com",
        "password" => "secret"
      }
    end
  end
end
