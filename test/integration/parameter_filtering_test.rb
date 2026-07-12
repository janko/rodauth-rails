require "test_helper"

class ParameterFilteringTest < ActionDispatch::IntegrationTest
  include TestSetupTeardown

  test "filters the rodauth token parameter from request logs" do
    get "/reset-password", params: {
      key: "secret",
      keyboard: "dvorak",
    }

    assert_equal "[FILTERED]", request.filtered_parameters["key"]
    assert_includes request.filtered_path, "key=[FILTERED]"
    assert_equal "dvorak", request.filtered_parameters["keyboard"]
  end
end
