require "test_helper"

class ControllerTest < IntegrationTest
  if ActionPack.version >= Gem::Version.new("5.0.0")
    test "defines #rodauth method on ActionController::API" do
      assert ActionController::API.method_defined?(:rodauth)
    end
  end
end
