require "test_helper"

class ConfigurationsTest < IntegrationTest
  test "multiple configurations" do
    visit "/secondary"

    assert_equal current_path, "/admin/login"
  end

  test "prefix with custom Roda router" do
    visit "/admin/custom1"
    assert_equal "Custom admin route", page.html
  end

  test "prefix with custom Rails route" do
    visit "/admin/custom2"
    assert_equal "Custom admin route", page.html
  end
end
