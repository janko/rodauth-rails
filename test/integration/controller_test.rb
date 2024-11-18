require "test_helper"

class ControllerTest < IntegrationTest
  test "defines #rodauth method on ActionController::API" do
    assert ActionController::API.method_defined?(:rodauth)
  end

  test "current account" do
    register(login: "user@example.com", verify: true)
    assert_includes page.text, "Authenticated as user@example.com"
  end

  test "executing controller methods" do
    visit "/"

    assert_match "controller method", page.text
  end

  test "rodauth response" do
    register
    logout

    page.driver.browser.get "/sign_in"

    assert_equal 302, page.status_code
    assert_equal "/", page.response_headers["Location"]
    assert_equal "true", page.response_headers["X-After"]
  end
end
