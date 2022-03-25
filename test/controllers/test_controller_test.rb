require "test_helper"

class TestControllerTest < ControllerTest
  test "integration" do
    get :auth2

    assert_response 302
    assert_redirected_to rodauth.login_url

    account = Account.create!(email: "user@example.com", password: "secret", status: "verified")
    login(account)

    get :auth2

    assert_response 200
  end

  private

  def login(account)
    rodauth.account_from_login(account.email)
    rodauth.login_session("password")
  end
end
