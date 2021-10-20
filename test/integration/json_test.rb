require "test_helper"

class JsonTest < IntegrationTest
  test "works with ActionController::API and JWT" do
    page.driver.browser.post "/jwt/create-account",
      { "login" => "user@example.com", "password" => "secret", "password-confirm" => "secret" }.to_json,
      { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/json" }

    assert_equal %({"success":"An email has been sent to you with a link to verify your account"}), page.html

    email = ActionMailer::Base.deliveries.last
    assert_match "Someone has created an account with this email address", email.body.to_s
  end

  test "works with ActionController::API and JSON" do
    page.driver.browser.post "/json/create-account",
      { "login" => "user@example.com", "password" => "secret", "password-confirm" => "secret" }.to_json,
      { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/json" }

    assert_equal %({"success":"An email has been sent to you with a link to verify your account"}), page.html

    email = ActionMailer::Base.deliveries.last
    assert_match "Someone has created an account with this email address", email.body.to_s
  end
end
