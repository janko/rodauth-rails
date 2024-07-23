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

  test "retrieves secret_key_base from env variable, credentials, or secrets" do
    Rails.env = "production"

    if Rails.gem_version < Gem::Version.new("7.1.0")
      Rails.application.secrets.secret_key_base = "secret"
      assert_equal "secret", Rodauth::Rails.secret_key_base
    end

    if Rails.gem_version >= Gem::Version.new("5.2.0")
      Rails.application.credentials.secret_key_base = "credential"
      reset_secret_key_base do
        assert_equal "credential", Rodauth::Rails.secret_key_base
      end

      ENV["SECRET_KEY_BASE"] = "environment"
      reset_secret_key_base do
        assert_equal "environment", Rodauth::Rails.secret_key_base
      end
      ENV.delete("SECRET_KEY_BASE")
    end
  ensure
    Rails.env = "test"
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

  def reset_secret_key_base
    original_secret_key_base = Rails.configuration.secret_key_base
    Rails.configuration.instance_variable_set(:@secret_key_base, nil)
    yield
  ensure
    Rails.configuration.secret_key_base = original_secret_key_base
  end
end
