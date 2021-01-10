require "test_helper"

class SessionTest < IntegrationTest
  test "resetting session on logout" do
    register

    old_session_id = page.find("#session_id").text

    logout

    new_session_id = page.find("#session_id").text

    refute_equal old_session_id, new_session_id
  end
end
