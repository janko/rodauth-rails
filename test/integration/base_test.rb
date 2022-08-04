require "test_helper"

require "sequel/model"

class BaseTest < IntegrationTest
  test "rails_account.nil? if no one logged in" do
    assert_nil Rodauth::Rails.rodauth.rails_account
  end

  test "build authenticated session" do
    account = Account.create!(email: "user@example.com", password: "password")

    rodauth = Rodauth::Rails.rodauth
    rodauth.scope.env["rodauth"] = rodauth

    error = assert_raises(Rodauth::InternalRequestError) { Rodauth::Rails.authenticated.call(rodauth.request) }
    assert_equal :login_required, error.reason

    rodauth.account_from_login("user@example.com")
    rodauth.login_session("password")
    assert_equal account, rodauth.rails_account    
  end
end