require "test_helper"

class ControllerTest < IntegrationTest
  if ActionPack.version >= Gem::Version.new("5.0")
    test "defines #rodauth method on ActionController::API" do
      assert ActionController::API.method_defined?(:rodauth)
    end
  end

  test "current account" do
    register(login: "user@example.com", verify: true)
    assert_text "Authenticated as user@example.com"

    # work around errors and warnings regarding composite primary keys
    capture_io { Account::ActiveSessionKey.delete_all }
    Account.last.destroy

    visit "/"
    assert_text "Please login to continue"
    assert_equal "/login", page.current_path
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
  end unless ActiveRecord::VERSION::MAJOR <= 4 && RUBY_ENGINE == "jruby"
end
