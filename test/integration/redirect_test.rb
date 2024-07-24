require "test_helper"

class RedirectTest < IntegrationTest
  test "requiring authentication from Rodauth app" do
    visit "/auth1"
    assert_equal "/login", current_path

    register
    visit "/auth1"

    assert_equal "/auth1", current_path
    assert_includes page.html, %(Authenticated as user@example.com)
  end

  test "requiring authentication from Rails controller" do
    visit "/auth2"
    assert_equal "/login", current_path

    register
    visit "/auth2"

    assert_equal "/auth2", current_path
    assert_includes page.html, %(Authenticated as user@example.com)
  end

  test "redirecting with query parameters" do
    register
    visit "/create-account?foo=bar"

    assert_equal "http://www.example.com/?foo=bar", current_url
  end
end
