require "test_helper"

class AssetsTest < IntegrationTest
  teardown do
    Rails.configuration.class.class_variable_get(:@@options).delete(:assets)
  end

  test "skips rodauth app for asset requests" do
    Rails.configuration.assets = Struct.new(:prefix).new("/assets")

    assert_raises ActionController::RoutingError do
      visit "/assets/foo"
    end
  end
end
