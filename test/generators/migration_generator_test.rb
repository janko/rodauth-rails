require "test_helper"
require "generators/rodauth/migration_generator"

class MigrationGeneratorTest < Rails::Generators::TestCase
  tests Rodauth::Rails::Generators::MigrationGenerator
  destination File.expand_path("#{__dir__}/../../tmp")
  setup :prepare_destination

  test "migration" do
    output = run_generator %w[otp sms_codes recovery_codes]

    migration_file = "db/migrate/create_rodauth_otp_sms_codes_recovery_codes.rb"
    migration_version = Regexp.escape("[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]")

    assert_migration migration_file, /class CreateRodauthOtpSmsCodesRecoveryCodes < ActiveRecord::Migration#{migration_version}/
    assert_migration migration_file, /create_table :account_otp_keys, id: false do/
    assert_migration migration_file, /create_table :account_sms_codes, id: false do/
    assert_migration migration_file, /create_table :account_recovery_codes, primary_key: \[:id, :code\] do/
    assert_migration migration_file, /t\.integer :id, primary_key: true/

    refute_includes output, "Rodauth configuration"
  end

  test "migration name" do
    run_generator %w[email_auth --name create_account_email_auth_keys]

    assert_migration "db/migrate/create_account_email_auth_keys.rb", /class CreateAccountEmailAuthKeys/
  end

  test "prefix" do
    output = run_generator %w[active_sessions base --prefix user]
    assert_migration "db/migrate/create_rodauth_user_active_sessions_base.rb", /create_table :user_active_session_keys/
    assert_includes output, <<-EOS
  active_sessions_table :user_active_session_keys
  active_sessions_account_id_column :user_id
  accounts_table :users
    EOS

    run_generator %w[remember --prefix admins]
    assert_migration "db/migrate/create_rodauth_admins_remember.rb", /create_table :admin_remember_keys/
  end

  test "migration uuid" do
    Rails.configuration.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    run_generator %w[otp]

    migration_file = "db/migrate/create_rodauth_otp.rb"

    assert_migration migration_file, /t\.uuid :id, primary_key: true/

    Rails.configuration.generators.options[:active_record].delete(:primary_key_type)
  end

  test "current timestamp column default" do
    run_generator %w[email_auth]

    assert_migration "db/migrate/create_rodauth_email_auth.rb", /default: -> { "CURRENT_TIMESTAMP" }/
  end

  test "no features" do
    output = run_generator %w[]

    assert_equal "No features specified!\n", output
    assert_no_file "db/migrate/create_rodauth_.rb"
  end

  test "invalid features" do
    output = run_generator %w[sms_codes active_session totp]

    assert_equal "No available migration for feature(s): active_session, totp\n", output
    assert_no_file "db/migrate/create_rodauth_otp.rb"
  end
end
