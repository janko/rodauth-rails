require "test_helper"

class JsonTest < IntegrationTest
  test "works with controller that inherits from ActionController::API" do
    page.driver.browser.post "/json/create-account",
      JSON.generate({
        "login"            => "user@example.com",
        "password"         => "secret",
        "password-confirm" => "secret",
      }),
      {
        "CONTENT_TYPE" => "application/json",
      }

    assert_equal %({"success":"An email has been sent to you with a link to verify your account"}), page.html

    email = ActionMailer::Base.deliveries.last
    assert_match "Someone has created an account with this email address", email.body.to_s
  end
end
