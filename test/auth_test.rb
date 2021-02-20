require "test_helper"

class AuthTest < UnitTest
  test "default configuration" do
    auth_class = Class.new(Rodauth::Rails::Auth)
    auth_class.configure { use_database_authentication_functions? true }

    auth_subclass = Class.new(auth_class)
    rodauth = auth_subclass.new(auth_subclass.roda_class.new({}))
    assert_equal true, rodauth.send(:use_database_authentication_functions?)
  end

  test "roda class" do
    auth_class = Class.new(Rodauth::Rails::Auth)
    assert_equal Rodauth::Rails.app, auth_class.roda_class

    assert_nil Rodauth::Rails::Auth.roda_class
  end

  test "inheriting features and routes" do
    auth_class = Class.new(Rodauth::Rails::Auth)
    auth_class.configure { enable :login }

    auth_subclass = Class.new(auth_class)
    auth_subclass.configure { enable :logout }

    assert_equal [:email_base, :rails, :login, :logout], auth_subclass.features
    assert_equal [:handle_login, :handle_logout], auth_subclass.routes
    assert_equal Hash["/login" => :handle_login, "/logout" => :handle_logout], auth_subclass.route_hash

    assert_equal [:email_base, :rails, :login], auth_class.features
    assert_equal [:handle_login], auth_class.routes
    assert_equal Hash["/login" => :handle_login], auth_class.route_hash
  end
end
