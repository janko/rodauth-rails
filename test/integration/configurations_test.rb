require "test_helper"

class ConfigurationsTest < IntegrationTest
  test "multiple configurations" do
    visit "/secondary"

    assert_equal current_path, "/admin/login"
  end
end
