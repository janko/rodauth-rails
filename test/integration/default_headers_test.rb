require "test_helper"

class DefaultHeaders < IntegrationTest
  test "included Action Dispatch default headers in response" do
    visit "/login"

    Rails.application.config.action_dispatch.default_headers.each do |key, value|
      assert_equal value, page.response_headers[key]
    end
  end
end
