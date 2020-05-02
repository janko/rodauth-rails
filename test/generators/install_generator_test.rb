require "test_helper"
require "generators/rodauth/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Rodauth::Rails::Generators::InstallGenerator
  destination File.expand_path("#{__dir__}/../../tmp")
  setup :prepare_destination

  test "rodauth initializer" do
    run_generator

    assert_file "config/initializers/rodauth.rb", <<-RUBY.strip_heredoc
      Rodauth::Rails.configure do |config|
        config.app = "RodauthApp"
      end
    RUBY
  end

  test "sequel initializer" do
    run_generator

    assert_file "config/initializers/sequel.rb", /Sequel\.sqlite\(test: false\)/
  end

  test "migration" do
    run_generator

    assert_migration "db/migrate/create_rodauth.rb", /ActiveRecord::Migration\[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}\]/
    assert_migration "db/migrate/create_rodauth.rb", /t\.string :email, null: false, index: { unique: true }/
  end

  test "app" do
    run_generator

    assert_file "lib/rodauth_app.rb", /class RodauthApp < Rodauth::Rails::App/
  end

  test "model" do
    run_generator

    assert_file "app/models/account.rb", /class Account < ApplicationRecord/
  end
end
