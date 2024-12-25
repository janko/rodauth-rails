require "test_helper"
require "generators/rodauth/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Rodauth::Rails::Generators::InstallGenerator
  destination File.expand_path("#{__dir__}/../../tmp")
  setup :prepare_destination

  test "migration" do
    run_generator

    migration_version = Regexp.escape("[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]")

    assert_migration "db/migrate/create_rodauth.rb", /class CreateRodauth < ActiveRecord::Migration#{migration_version}/
    assert_migration "db/migrate/create_rodauth.rb", /create_table :accounts do/
    assert_migration "db/migrate/create_rodauth.rb", /t\.string :email, null: false/
    assert_migration "db/migrate/create_rodauth.rb", /t.index :email, unique: true, where: ".+"/
  end

  test "rodauth initializer" do
    run_generator

    assert_file "config/initializers/rodauth.rb", /Rodauth::Rails.configure do |config|/
  end

  test "sequel integration" do
    begin
      db = Sequel::DATABASES.pop
      run_generator
    ensure
      Sequel::DATABASES.push(db)
    end

    if RUBY_ENGINE == "jruby"
      assert_file "app/misc/rodauth_main.rb", %r{Sequel\.connect\("jdbc:sqlite://", extensions: :activerecord_connection.*\)}
    else
      assert_file "app/misc/rodauth_main.rb", %r{Sequel\.sqlite\(extensions: :activerecord_connection.*\)}
    end
    assert_file "app/misc/rodauth_main.rb", /convert_token_id_to_integer\? { Account.columns_hash\["id"\]\.type == :integer }/

    assert_file "Gemfile", /gem ("|')sequel-activerecord_connection("|')/
    assert_file "Gemfile", /gem ("|')after_commit_everywhere("|')/ if ActiveRecord.version < Gem::Version.new("7.2")
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
    assert_file "app/misc/rodauth_main.rb", /# accounts_table :users/

    assert_file "Gemfile", /gem ("|')bcrypt("|')/
    assert_file "Gemfile", /gem ("|')tilt("|')/
  end

  test "app with --json option" do
    run_generator %w[--json]

    assert_file "app/misc/rodauth_main.rb", /:login, :logout, :remember, :json,$/
    assert_file "app/misc/rodauth_main.rb", /only_json\? true/
  end

  test "app with --jwt option" do
    run_generator %w[--jwt]

    assert_file "app/misc/rodauth_main.rb", /:login, :logout, :jwt,$/
    assert_file "app/misc/rodauth_main.rb", /jwt_secret /

    assert_file "Gemfile", /gem ("|')jwt("|')/
  end

  test "app with --argon2 option" do
    run_generator %w[--argon2]

    assert_file "app/misc/rodauth_main.rb", /:argon2/
    assert_file "app/misc/rodauth_main.rb", /argon2_secret/

    assert_file "Gemfile" do |content|
      assert_includes content, "argon2"
      refute_includes content, "bcrypt"
    end
  end

  test "controller" do
    run_generator

    assert_file "app/controllers/rodauth_controller.rb", /class RodauthController < ApplicationController/
  end

  test "model" do
    run_generator

    assert_file "app/models/account.rb", /class Account < ApplicationRecord/
    if ActiveRecord.version >= Gem::Version.new("7.0")
      assert_file "app/models/account.rb", /enum :status, { unverified: 1, verified: 2, closed: 3 }/
    else
      assert_file "app/models/account.rb", /enum status: { unverified: 1, verified: 2, closed: 3 }/
    end
  end

  test "fixtures" do
    run_generator

    assert_file "test/fixtures/accounts.yml", /password_hash/ # No tests for the rspec branch
  end

  test "table" do
    %w[admins admin Admin].each do |argument|
      output = run_generator [argument]

      assert_file "app/misc/rodauth_main.rb", /^\s+accounts_table :admins$/
      assert_file "app/misc/rodauth_main.rb", /^\s+remember_table :admin_remember_keys$/
      assert_migration "db/migrate/create_rodauth.rb", /create_table :admins do/
      assert_migration "db/migrate/create_rodauth.rb", /create_table :admin_remember_keys/
      assert_file "app/models/admin.rb", /class Admin </
      assert_file "test/fixtures/admins.yml"
      refute_includes output, "Rodauth configuration"

      prepare_destination
    end
  end

  def prepare_destination
    super
    File.write("#{destination_root}/Gemfile", %(source "https://rubygems.org"\n))
  end
end
