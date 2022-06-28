require "test_helper"
require "generators/rodauth/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Rodauth::Rails::Generators::InstallGenerator
  destination File.expand_path("#{__dir__}/../../tmp")
  setup :prepare_destination

  test "migration" do
    run_generator

    if ActiveRecord.version >= Gem::Version.new("5.0")
      migration_version = Regexp.escape("[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]")
    end

    assert_migration "db/migrate/create_rodauth.rb", /class CreateRodauth < ActiveRecord::Migration#{migration_version}/
    assert_migration "db/migrate/create_rodauth.rb", /create_table :accounts do/
    assert_migration "db/migrate/create_rodauth.rb", /t\.string :email, null: false/
    assert_migration "db/migrate/create_rodauth.rb", /t.index :email, unique: true, where: ".+"/
  end

  test "rodauth initializer" do
    run_generator

    assert_file "config/initializers/rodauth.rb", <<-RUBY.strip_heredoc
      Rodauth::Rails.configure do |config|
        config.app = "RodauthApp"
      end
    RUBY
  end

  test "sequel initializer" do
    db = Sequel::DATABASES.pop
    run_generator
    Sequel::DATABASES.push(db)

    if RUBY_ENGINE == "jruby"
      assert_file "config/initializers/sequel.rb", /Sequel\.connect\("jdbc:sqlite:\/\/", extensions: :activerecord_connection\)/
    else
      assert_file "config/initializers/sequel.rb", /Sequel\.connect\("sqlite:\/\/", extensions: :activerecord_connection\)/
    end
  end

  test "app" do
    run_generator

    assert_file "app/misc/rodauth_app.rb", /class RodauthApp < Rodauth::Rails::App/
    assert_file "app/misc/rodauth_app.rb", /rodauth\.load_memory/

    assert_file "app/misc/rodauth_main.rb", /class RodauthMain < Rodauth::Rails::Auth/
    assert_file "app/misc/rodauth_main.rb", /configure do/
    assert_file "app/misc/rodauth_main.rb", /:login, :logout, :remember,$/
    assert_file "app/misc/rodauth_main.rb", /hmac_secret "[a-z0-9]{128}"/
    assert_file "app/misc/rodauth_main.rb", /rails_controller { RodauthController }/
    assert_file "app/misc/rodauth_main.rb", /flash_notice_key/
    assert_file "app/misc/rodauth_main.rb", /Remember Feature/
    assert_file "app/misc/rodauth_main.rb", /logout_redirect/
  end

  test "app with --json option" do
    run_generator %w[--json]

    assert_file "app/misc/rodauth_main.rb", /:login, :logout, :remember, :json,$/
    assert_file "app/misc/rodauth_main.rb", /only_json\? true/
  end

  test "app with --jwt option" do
    run_generator %w[--jwt]

    assert_file "app/misc/rodauth_main.rb", /:login, :logout, :jwt,$/
    assert_file "app/misc/rodauth_main.rb", /jwt_secret "[a-z0-9]{128}"/
  end

  test "controller" do
    run_generator

    assert_file "app/controllers/rodauth_controller.rb", /class RodauthController < ApplicationController/
  end

  test "model" do
    run_generator

    assert_file "app/models/account.rb", /class Account < ApplicationRecord/
    if ActiveRecord.version >= Gem::Version.new("7.0")
      assert_file "app/models/account.rb", /enum :status, unverified: 1, verified: 2, closed: 3/
    else
      assert_file "app/models/account.rb", /enum status: { unverified: 1, verified: 2, closed: 3 }/
    end
  end

  test "mailer" do
    run_generator

    assert_file "app/mailers/rodauth_mailer.rb", /class RodauthMailer < ApplicationMailer/

    %w[
      verify_account verify_login_change unlock_account reset_password
      password_changed email_auth
    ].each do |template|
      assert_file "app/views/rodauth_mailer/#{template}.text.erb"
    end
  end

  test "fixture" do
    run_generator

    assert_file "app/test/fixtures/accounts.yml"
  end
end
