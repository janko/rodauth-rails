require "test_helper"
require "ostruct"

class AssetsTest < IntegrationTest
  teardown do
    Rails.application.config.class.class_variable_get(:@@options).delete(:assets)
  end

  test "skips rodauth app for asset requests" do
    [OpenStruct.new(prefix: "/assets"), OpenStruct.new(prefix: "/assets")].each do |assets|
      Rails.application.config.assets = assets

      assert_raises ActionController::RoutingError do
        visit "/assets/foo"
      end
    end
  end
end
