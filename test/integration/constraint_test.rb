require "test_helper"

class ConstraintTest < IntegrationTest
  test "authenticated constraint" do
    visit "/authenticated"
    assert_equal "/login", page.current_path
    assert_match "Please login to continue", page.find("#alert").text

    register
    visit "/authenticated"
    assert_equal "/authenticated", page.current_path
    assert_includes page.html, %(Authenticated as user@example.com)
  end
end
