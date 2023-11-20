require "test_helper"

class RoutesTest < IntegrationTest
  test "routes for default configuration" do
    assert_equal "/login", login_path
    assert_equal "http://www.example.com/login", login_url
  end

  test "routes for secondary configuration" do
    assert_equal "/admin/login", admin_login_path
    assert_equal "http://www.example.com/admin/login", admin_login_url
  end

  test "changed routes" do
    assert_equal "/change-email", change_login_path
    assert_equal "http://www.example.com/change-email", change_login_url
  end

  test "current url" do
    visit "/reset-password-request"
    click_on "Croatian"
    assert_match %r{/reset-password-request\?locale=hr$}, current_url
  end

  test "disabled routes" do
    assert_raises(NameError) { verify_login_change_path }
  end
end
