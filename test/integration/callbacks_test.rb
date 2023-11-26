require "test_helper"

class CallbacksTest < IntegrationTest
  test "runs callbacks" do
    visit "/login"

    assert_match "login-form", page.html
    assert_equal 200, page.status_code
    assert_equal "true", page.response_headers["X-Before-Action"]
    assert_equal "true", page.response_headers["X-After-Action"]
    assert_equal "true", page.response_headers["X-Before-Around-Action"]
    assert_equal "true", page.response_headers["X-After-Around-Action"]
  end

  test "runs callbacks for specific actions" do
    visit "/create-account"
    assert_equal "true", page.response_headers["X-Before-Specific-Action"]

    visit "/login"
    assert_nil page.response_headers["X-Before-Specific-Action"]
  end

  test "handles rendering in callback chain" do
    visit "/login?early_return=true&fail=true"

    assert_equal "early return", page.html
    assert_equal 201, page.status_code
    assert_equal "true", page.response_headers["X-Before-Action"]
  end
end
