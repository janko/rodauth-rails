require "test_helper"
require "generators/rodauth/migration_generator"

class MigrationGeneratorTest < Rails::Generators::TestCase
  tests Rodauth::Rails::Generators::MigrationGenerator
  destination File.expand_path("#{__dir__}/../../tmp")
  setup :prepare_destination

  test "migration" do
    run_generator %w[otp sms_codes recovery_codes]

    if ActiveRecord.version >= Gem::Version.new("5.0")
      migration_version = Regexp.escape("[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]")
    end

    migration_file = "db/migrate/create_rodauth_otp_sms_codes_recovery_codes.rb"

    assert_migration migration_file, /class CreateRodauthOtpSmsCodesRecoveryCodes < ActiveRecord::Migration#{migration_version}/
    assert_migration migration_file, /create_table :account_otp_keys do/
    assert_migration migration_file, /create_table :account_sms_codes do/
    assert_migration migration_file, /create_table :account_recovery_codes, primary_key: \[:id, :code\] do/
    assert_migration migration_file, /t\.column :id, :bigint/
  end

  test "migration name" do
    run_generator %w[email_auth --name create_account_email_auth_keys]

    assert_migration "db/migrate/create_account_email_auth_keys.rb", /class CreateAccountEmailAuthKeys/
  end

  test "migration uuid" do
    Rails.application.config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    run_generator %w[otp sms_codes recovery_codes]

    migration_file = "db/migrate/create_rodauth_otp_sms_codes_recovery_codes.rb"

    assert_migration migration_file, /create_table :account_otp_keys, id: :uuid do/
    assert_migration migration_file, /create_table :account_sms_codes, id: :uuid do/
    assert_migration migration_file, /t\.column :id, :uuid/

    Rails.application.config.generators.options[:active_record].delete(:primary_key_type)
  end

  test "current timestamp column default" do
    run_generator %w[email_auth]

    if ActiveRecord.version >= Gem::Version.new("5.0")
      assert_migration "db/migrate/create_rodauth_email_auth.rb", /default: -> { "CURRENT_TIMESTAMP" }/
    else
      assert_migration "db/migrate/create_rodauth_email_auth.rb", /default: OpenStruct\.new\(quoted_id: "CURRENT_TIMESTAMP"\)/
    end
  end
end
