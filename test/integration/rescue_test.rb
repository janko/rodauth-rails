require "test_helper"

class RescueTest < IntegrationTest
  test "runs #rescue_from handlers around Rodauth actions" do
    visit "/login?raise=true"

    assert_equal "rescued response", page.html
    assert_equal 500,                page.status_code
  end
end
