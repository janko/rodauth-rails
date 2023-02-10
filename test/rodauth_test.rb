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

  test "returns current account if logged in" do
    assert_nil Rodauth::Rails.rodauth.rails_account

    account = Account.create!(email: "user@example.com", status: "verified")
    assert_equal account, Rodauth::Rails.rodauth(account_id: account.id).rails_account

    rodauth = RodauthApp.rodauth.allocate
    rodauth.instance_eval { @account = account_ds(account.id).first! }
    assert_equal account, rodauth.rails_account
  end

  test "table_prefix renames table and foreign key column names" do
    auth_class = Class.new(RodauthMain)
    auth_class.configure do
      table_prefix :user
      enable :single_session
    end
    auth_class.allocate.post_configure

    assert_equal :users, auth_class.allocate.accounts_table
    assert_equal :user_verification_keys, auth_class.allocate.verify_account_table
    assert_equal :user_session_keys, auth_class.allocate.single_session_table

    auth_subclass = Class.new(auth_class)
    auth_subclass.configure { enable :account_expiration }
    auth_subclass.allocate.post_configure

    assert_equal :users, auth_subclass.allocate.accounts_table
    assert_equal :user_verification_keys, auth_subclass.allocate.verify_account_table
    assert_equal :user_activity_times, auth_subclass.allocate.account_activity_table
  end
end
