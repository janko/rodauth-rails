require "test_helper"

class IntrospectionTest < IntegrationTest
  test "middleware inspect output" do
    page.driver.browser.get "/roda"

    inspect = JSON.parse(page.body)

    assert_equal "RodauthApp::Middleware", inspect["class"]
    assert_match /#<RodauthApp::Middleware request=.+ response=.+>/, inspect["instance"]
  end
end
