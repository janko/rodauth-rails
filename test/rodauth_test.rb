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

    capture_io { rodauth = Rodauth::Rails.rodauth(query: { "foo" => { "bar" => "baz" } }) }
    assert_equal "baz", rodauth.raw_param("foo")["bar"]

    capture_io { rodauth = Rodauth::Rails.rodauth(form: { "foo" => { "bar" => "baz" } }) }
    assert_equal "baz", rodauth.raw_param("foo")["bar"]
  end

  test "allows setting account" do
    account = Account.create!(email: "user@example.com")

    rodauth = Rodauth::Rails.rodauth(account: account)
    assert_equal "user@example.com", rodauth.send(:email_to)
    assert_equal account.id, rodauth.session_value
  end

  test "allows setting additional internal request options" do
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
    Account.create!(email: "user@example.com", password: "secret")

    rodauth = Rodauth::Rails.rodauth
    rodauth.scope.env["rodauth"] = rodauth

    error = assert_raises(Rodauth::InternalRequestError) { Rodauth::Rails.authenticated.call(rodauth.request) }
    assert_equal :login_required, error.reason

    rodauth.account_from_login("user@example.com")
    rodauth.login_session("password")
    assert_equal true, Rodauth::Rails.authenticated.call(rodauth.request)

    rodauth.add_recovery_code
    rodauth.session.delete(:two_factor_auth_setup)
    error = assert_raises(Rodauth::InternalRequestError) { Rodauth::Rails.authenticated.call(rodauth.request) }
    assert_equal :two_factor_need_authentication, error.reason

    rodauth.send(:two_factor_update_session, "recovery_codes")
    assert_equal true, Rodauth::Rails.authenticated.call(rodauth.request)

    constraint = Rodauth::Rails.authenticated { |rodauth| rodauth.authenticated_by.include?("otp") }
    assert_equal false, constraint.call(rodauth.request)

    rodauth.scope.env["rodauth.admin"] = rodauth.scope.env.delete("rodauth")
    constraint = Rodauth::Rails.authenticated(:admin)
    assert_equal true, constraint.call(rodauth.request)
  end
end
