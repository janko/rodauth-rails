require "test_helper"

class TestControllerTest < ActionController::TestCase
  include TestSetupTeardown

  test "integration" do
    get :auth2
    assert_response 302
    assert_redirected_to "/login"
    assert_equal "Please login to continue", flash[:alert]

    account = Account.create!(email: "user@example.com", password: "secret", status: "verified")
    login(account)

    get :auth2
    assert_response 200

    # session state is retained on further requests
    get :auth2
    assert_response 200

    logout

    get :auth2
    assert_response 302
    assert_equal "Please login to continue", flash[:alert]
  end

  private

  def login(account)
    rodauth.account_from_login(account.email)
    rodauth.login_session("password")
  end

  def logout
    rodauth.logout
  end
end
