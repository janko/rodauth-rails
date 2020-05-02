require "test_helper"

class AuthenticationTest < IntegrationTest
  test "requiring authentication from Rodauth app" do
    visit "/auth1"
    assert_equal current_path, "/login"

    register
    visit "/auth1"

    assert_equal current_path, "/auth1"
    assert_includes page.html, %(Authenticated as user@example.com)
  end

  test "requiring authentication from Rails controller" do
    visit "/auth2"
    assert_equal current_path, "/login"

    register
    visit "/auth2"

    assert_equal current_path, "/auth2"
    assert_includes page.html, %(Authenticated as user@example.com)
  end
end
