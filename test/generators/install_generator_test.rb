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
    assert_migration "db/migrate/create_rodauth.rb", /t\.string :email, null: false, index: { unique: true }/
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

    assert_file "app/lib/rodauth_app.rb", /class RodauthApp < Rodauth::Rails::App/
    assert_file "app/lib/rodauth_app.rb", /configure do/
    assert_file "app/lib/rodauth_app.rb", /:login, :logout, :remember,$/
    assert_file "app/lib/rodauth_app.rb", /hmac_secret "[a-z0-9]{128}"/
    assert_file "app/lib/rodauth_app.rb", /rails_controller { RodauthController }/
    assert_file "app/lib/rodauth_app.rb", /flash_notice_key/
    assert_file "app/lib/rodauth_app.rb", /Remember Feature/
    assert_file "app/lib/rodauth_app.rb", /logout_redirect/
    assert_file "app/lib/rodauth_app.rb", /rodauth\.load_memory/
  end

  test "app with --json option" do
    run_generator %w[--json]

    assert_file "app/lib/rodauth_app.rb", /:login, :logout, :remember, :json,$/
    assert_file "app/lib/rodauth_app.rb", /only_json\? true/
  end

  test "app with --jwt option" do
    run_generator %w[--jwt]

    assert_file "app/lib/rodauth_app.rb", /:login, :logout, :jwt,$/
    assert_file "app/lib/rodauth_app.rb", /jwt_secret "[a-z0-9]{128}"/
  end

  test "controller" do
    run_generator

    assert_file "app/controllers/rodauth_controller.rb", /class RodauthController < ApplicationController/
  end

  test "model" do
    run_generator

    assert_file "app/models/account.rb", /class Account < ApplicationRecord/
  end
end
