require "test_helper"

class RodauthTest < ActiveSupport::TestCase
  test "allows retrieving Rodauth instance" do
    rodauth = Rodauth::Rails.rodauth

    assert_kind_of Rodauth::Auth, rodauth
    assert_equal "https://example.com/login", rodauth.login_url
  end
end
