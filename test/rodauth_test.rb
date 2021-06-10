require "test_helper"

class RodauthTest < UnitTest
  test "allows retrieving a Rodauth instance" do
    rodauth = Rodauth::Rails.rodauth

    assert_kind_of Rodauth::Auth, rodauth
    assert_equal "https://example.com/login", rodauth.login_url
  end

  test "allows settings query and form params" do
    rodauth = Rodauth::Rails.rodauth
    assert_nil rodauth.param_or_nil("foo")

    rodauth = Rodauth::Rails.rodauth(query: { "foo" => { "bar" => "baz" } })
    assert_equal "baz", rodauth.request.GET["foo"]["bar"]
    assert_equal "baz", rodauth.raw_param("foo")["bar"]

    rodauth = Rodauth::Rails.rodauth(form: { "foo" => { "bar" => "baz" } })
    assert_equal "baz", rodauth.request.POST["foo"]["bar"]
    assert_equal "baz", rodauth.raw_param("foo")["bar"]
  end

  test "allows setting session" do
    rodauth = Rodauth::Rails.rodauth
    assert_equal Hash.new, rodauth.session

    rodauth = Rodauth::Rails.rodauth(session: { account_id: 1 })
    assert_equal Hash[account_id: 1], rodauth.session
    assert rodauth.logged_in?

    rodauth = Rodauth::Rails.rodauth(:json, session: { account_id: 1 })
    assert_equal Hash[account_id: 1], rodauth.session
    assert rodauth.logged_in?
  end

  test "allows setting account" do
    account = Account.create!(email: "user@example.com")

    rodauth = Rodauth::Rails.rodauth(account: account)
    assert_equal "user@example.com", rodauth.send(:email_to)
    assert_equal account.id, rodauth.session_value
  end

  test "allows setting additional env values" do
    rodauth = Rodauth::Rails.rodauth(env: { "HTTP_USER_AGENT" => "API" })
    assert_equal "API", rodauth.request.user_agent
  end

  test "retrieves secret_key_base from env variable, credentials, or secrets" do
    Rails.env = "production"

    Rails.application.secrets.secret_key_base = "secret"
    assert_equal "secret", Rodauth::Rails.secret_key_base

    if Rails.gem_version >= Gem::Version.new("5.2.0")
      Rails.application.credentials.secret_key_base = "credential"
      assert_equal "credential", Rodauth::Rails.secret_key_base

      ENV["SECRET_KEY_BASE"] = "environment"
      assert_equal "environment", Rodauth::Rails.secret_key_base
      ENV.delete("SECRET_KEY_BASE")
    end

    Rails.env = "test"
  end

  test "builds authenticated constraint" do
    account_id = DB[:accounts].insert(email: "user@example.com")
    DB[:account_password_hashes].insert(id: account_id, password_hash: BCrypt::Password.create("secret", cost: 1))

    rodauth = Rodauth::Rails.rodauth
    rodauth.scope.env["rodauth"] = rodauth
    rodauth.scope.env["rack.session"] = {}

    res = catch(:halt) { Rodauth::Rails.authenticated.call(rodauth.request) }
    assert_equal 302,      res[0]
    assert_equal "/login", res[1]["Location"]

    rodauth.account_from_login("user@example.com")
    rodauth.login_session("password")
    assert_equal true, Rodauth::Rails.authenticated.call(rodauth.request)

    rodauth.add_recovery_code
    rodauth.session.delete(:two_factor_auth_setup)
    res = catch(:halt) { Rodauth::Rails.authenticated.call(rodauth.request) }
    assert_equal 302,                 res[0]
    assert_equal "/multifactor-auth", res[1]["Location"]

    rodauth.send(:two_factor_update_session, "recovery_codes")
    assert_equal true, Rodauth::Rails.authenticated.call(rodauth.request)

    constraint = Rodauth::Rails.authenticated { |rodauth| rodauth.authenticated_by.include?("otp") }
    assert_equal false, constraint.call(rodauth.request)

    rodauth.scope.env["rodauth.admin"] = rodauth.scope.env.delete("rodauth")
    constraint = Rodauth::Rails.authenticated(:admin)
    assert_equal true, constraint.call(rodauth.request)
  end
end
