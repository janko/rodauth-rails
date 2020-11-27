require "test_helper"

class RodauthTest < ActiveSupport::TestCase
  test "allows retrieving Rodauth instance" do
    rodauth = Rodauth::Rails.rodauth

    assert_kind_of Rodauth::Auth, rodauth
    assert_equal "https://example.com/login", rodauth.login_url
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
end
