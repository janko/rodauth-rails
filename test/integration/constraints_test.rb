require "test_helper"

class ConstraintsTest < IntegrationTest
  test "requiring authentication from Rodauth app" do
    visit "/under_constraints"
    assert_equal current_path, "/login"

    register
    visit "/under_constraints"

    assert_equal current_path, "/under_constraints"
    assert_includes page.html, %(Authenticated as user@example.com)
  end
end
