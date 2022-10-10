require "test_helper"

class ConfigurationsTest < IntegrationTest
  test "multiple configurations" do
    visit "/secondary"

    assert_equal current_path, "/admin/login"
  end

  test "prefix with custom routes" do
    visit "/admin/custom"

    assert_equal "Custom admin route", page.html
  end
end
