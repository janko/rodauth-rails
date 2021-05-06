require "test_helper"

class LoggingTest < IntegrationTest
  test "logs processing and completion of a request" do
    logged = capture_log do
      visit "/login"
    end

    assert_match /Started GET "\/login" for 127\.0\.0\.1/, logged
    assert_match /Processing by RodauthApp as HTML/, logged
    refute_match /Parameters/, logged
    if ::Rails.gem_version >= Gem::Version.new("6.0")
      assert_match /Completed 200 OK in \d+ms \(ActiveRecord: \d+\.\d+ms | Allocations: \d+\)/, logged
    else
      assert_match /Completed 200 OK in \d+ms \(ActiveRecord: \d+\.\d+ms\)/, logged
    end
  end

  test "logs JSON requests" do
    logged = capture_log do
      page.driver.browser.post "/json/login",
        { "login" => "user@example.com", "password" => "secret" }.to_json,
        { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/json" }
    end

    assert_match /Processing by RodauthApp as JSON/, logged
    assert_match /\s{2}Parameters: {"login"=>"user@example\.com", "password"=>"secret"}/, logged
    assert_match /Completed 401 Unauthorized/, logged
  end

  test "handles early response via callback" do
    logged = capture_log do
      visit "/login?early_return=true"
    end

    assert_match /Started GET "\/login\?early_return=true" for 127\.0\.0\.1/, logged
    assert_match /Processing by RodauthApp as HTML/, logged
    assert_match /Completed 201 Created in \d+ms/, logged
  end

  test "handles invalid HTTP verb" do
    logged = capture_log do
      page.driver.browser.head "/login"
    end

    assert_match /Completed 404 Not Found in \d+ms/, logged
  end

  private

  def capture_log
    io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(io)
    yield
    Rails.logger = original_logger
    io.string
  end
end
