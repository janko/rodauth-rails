require "test_helper"

class InstrumentationTest < IntegrationTest
  test "logs processing and completion of a request" do
    logged = capture_log do
      visit "/login"
    end

    assert_match /Processing by RodauthApp#call as HTML/, logged
    refute_match /Parameters/, logged
    if ::Rails.gem_version >= Gem::Version.new("6.0")
      assert_match /Completed 200 OK in \d+ms \(Views: \d+ms | ActiveRecord: \d+\.\d+ms | Allocations: \d+\)/, logged
    else
      assert_match /Completed 200 OK in \d+ms \(Views: \d+ms | ActiveRecord: \d+\.\d+ms\)/, logged
    end
  end

  test "logs JSON requests" do
    logged = capture_log do
      page.driver.browser.post "/json/login",
        { "login" => "user@example.com", "password" => "secret" }.to_json,
        { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/json" }
    end

    assert_match /Processing by RodauthApp#call as JSON/, logged
    assert_match /Parameters: {"login"=>"user@example\.com", "password"=>"secret"}/, logged
    assert_match /Completed 401 Unauthorized/, logged
  end

  test "logs redirects" do
    logged = capture_log do
      visit "/change-password"
    end

    assert_match /Processing by RodauthApp#call as HTML/, logged
    assert_match /Redirected to \/login/, logged
    assert_match /Completed 302 Found/, logged
  end

  test "handles early response via callback" do
    logged = capture_log do
      visit "/login?early_return=true"
    end

    assert_match /Processing by RodauthApp#call as HTML/, logged
    assert_match /Completed 201 Created in \d+ms/, logged
  end

  test "logs response status when redirecting inside controller" do
    logged = capture_log do
      visit "/auth2"
    end

    assert_match /Completed 302 Found/, logged
  end

  test "logs response status when halting inside controller" do
    logged = capture_log do
      visit "/auth_json"
    end

    assert_match /Completed 401 Unauthorized/, logged
  end

  private

  def capture_log
    io = StringIO.new
    original_logger = ActionController::Base.logger
    ActionController::Base.logger = Logger.new(io)
    yield
    ActionController::Base.logger = original_logger
    io.string
  end
end
