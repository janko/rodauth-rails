require "test_helper"

class HeadersTest < IntegrationTest
  test "included Action Dispatch default headers in response" do
    visit "/login"

    Rails.application.config.action_dispatch.default_headers.each do |key, value|
      assert_equal value, page.response_headers[key]
    end
  end

  test "extending remember cookie deadline" do
    register(login: "user@example.com")
    login # remember login

    cookies = page.driver.browser.rack_mock_session.cookie_jar

    assert cookies["_remember"] # remember cookie was set

    cookies.delete("_rails_app_session") # simulate session expiring

    visit "/" # autologin from remember cookie

    assert_match "Authenticated as user@example.com", page.text
    assert_match "_remember", page.response_headers["Set-Cookie"] # remember deadline extended
  end if Gem::Version.new(Rack::Test::VERSION) >= Gem::Version.new("1.0")
end
