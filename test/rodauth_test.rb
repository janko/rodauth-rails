require "test_helper"
require "sequel/model"

class RodauthTest < UnitTest
  test "allows retrieving a Rodauth instance" do
    rodauth = Rodauth::Rails.rodauth

    assert_kind_of Rodauth::Auth, rodauth
    assert_equal "https://example.com/login", rodauth.login_url
  end

  test "allows setting Active Record account" do
    account = Account.create!(email: "user@example.com")

    rodauth = Rodauth::Rails.rodauth(account: account)
    assert_equal "user@example.com", rodauth.send(:email_to)
    assert_equal account.id, rodauth.session_value
    assert_equal account.status_before_type_cast, rodauth.account[:status]
  end

  test "allows setting Sequel account" do
    account_class = Class.new(Sequel::Model)
    account_class.dataset = :accounts
    account = account_class.create(email: "user@example.com")

    rodauth = Rodauth::Rails.rodauth(account: account)
    assert_equal "user@example.com", rodauth.send(:email_to)
    assert_equal account.id, rodauth.session_value
  end

  test "allows setting additional internal request options" do
    rodauth = Rodauth::Rails.rodauth(env: { "HTTP_USER_AGENT" => "API" })
    assert_equal "API", rodauth.request.user_agent
  end

  test "builds authenticate constraint" do
    account = Account.create!(email: "user@example.com", password: "secret", status: "verified")

    rodauth = Rodauth::Rails.rodauth
    rodauth.scope.env["rodauth"] = rodauth
    request = rodauth.request

    error = assert_raises(Rodauth::InternalRequestError) { Rodauth::Rails.authenticate.call(request) }
    assert_equal :login_required, error.reason

    rodauth.account_from_login("user@example.com")
    rodauth.login_session("password")
    assert_equal true, Rodauth::Rails.authenticate.call(request)

    rodauth.add_recovery_code
    rodauth.session.delete(:two_factor_auth_setup)
    error = assert_raises(Rodauth::InternalRequestError) { Rodauth::Rails.authenticate.call(request) }
    assert_equal :two_factor_need_authentication, error.reason

    rodauth.send(:two_factor_update_session, "recovery_codes")
    assert_equal true, Rodauth::Rails.authenticate.call(request)

    constraint = Rodauth::Rails.authenticate { |rodauth| rodauth.authenticated_by.include?("otp") }
    assert_equal false, constraint.call(request)

    rodauth.scope.env["rodauth.admin"] = rodauth.scope.env.delete("rodauth")
    assert_equal true, Rodauth::Rails.authenticate(:admin).call(request)

    capture_io { account.destroy } # silence composite primary key warnings
    error = assert_raises(Rodauth::InternalRequestError) { Rodauth::Rails.authenticate(:admin).call(request) }
    assert_equal :login_required, error.reason
  end

  test "allows retrieving current account model instance" do
    assert_nil Rodauth::Rails.rodauth.rails_account

    account = Account.create!(email: "user@example.com", status: "verified")
    assert_equal account, Rodauth::Rails.rodauth(account_id: account.id).rails_account

    rodauth = RodauthApp.rodauth.allocate
    rodauth.account_from_id(account.id)
    assert_equal account, rodauth.rails_account

    account2 = Account.create!(email: "user2@example.com", status: "verified")
    rodauth.account_from_id(account2.id)
    assert_equal account2, rodauth.rails_account
  end

  test "allows using as a library" do
    Account.create!(email: "user@example.com", password: "secret", status: "verified")

    rodauth = Rodauth::Rails.lib(render: false) { enable :login }
    rodauth.login(login: "user@example.com", password: "secret")
    assert_raises Rodauth::InternalRequestError do
      rodauth.login(login: "unknown@example.com", password: "secret")
    end

    refute_includes rodauth.roda_class.instance_methods, :render
  end

  test "allows skipping render plugin" do
    app = Class.new(Rodauth::Rails::App)
    app.configure(render: false) {  }

    refute_includes app.instance_methods, :render
  end
end
