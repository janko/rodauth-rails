class CreateRodauth < ActiveRecord::Migration<%= migration_version %>
  def up
<% if adapter == "postgresql" -%>
    enable_extension "citext"
<% end -%>

    # Used by the account verification and close account features
    create_table :account_statuses do |t|
      t.string :name, null: false, unique: true
    end
    execute "INSERT INTO account_statuses (id, name) VALUES (1, 'Unverified'), (2, 'Verified'), (3, 'Closed')"

    create_table :accounts, id: :bigint do |t|
      t.references :status, foreign_key: { to_table: :account_statuses }, null: false, default: 1
<% if adapter == "postgresql" -%>
      t.citext :email, null: false
      t.index :email, unique: true, where: "status_id IN (1, 2)"
<% else -%>
      t.string :email, null: false
      t.index :email, unique: true
<% end -%>
    end

    create_table :account_password_hashes, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.string :password_hash, null: false
    end

    # Used by the disallow_password_reuse feature
    create_table :account_previous_password_hashes, id: :bigint do |t|
      t.references :account
      t.string :password_hash, null: false
    end

    # Used by the password reset feature
    create_table :account_password_reset_keys, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, null: false
      t.datetime :email_last_sent, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the account verification feature
    create_table :account_verification_keys, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :requested_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :email_last_sent, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the verify login change feature
    create_table :account_login_change_keys, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.string :login, null: false
      t.datetime :deadline, null: false
    end

    # Used by the remember me feature
    create_table :account_remember_keys, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, null: false
    end

    # Used by the lockout feature
    create_table :account_login_failures, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.integer :number, null: false, default: 1
    end
    create_table :account_lockouts, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, null: false
      t.datetime :email_last_sent
    end

    # Used by the email auth feature
    create_table :account_email_auth_keys, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, null: false
      t.datetime :email_last_sent, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the password expiration feature
    create_table :account_password_change_times, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.datetime :changed_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the account expiration feature
    create_table :account_activity_times, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.datetime :last_activity_at, null: false
      t.datetime :last_login_at, null: false
      t.datetime :expired_at
    end

    # Used by the single session feature
    create_table :account_session_keys, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
    end

    # Used by the otp feature
    create_table :account_otp_keys, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.integer :num_failures, null: false, default: 0
      t.datetime :last_use, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the recovery codes feature
    create_table :account_recovery_codes, primary_key: [:id, :code] do |t|
      t.bigint :id
      t.foreign_key :accounts, column: :id
      t.string :code
    end

    # Used by the sms codes feature
    create_table :account_sms_codes, id: :bigint do |t|
      t.foreign_key :accounts, column: :id
      t.string :phone_number, null: false
      t.integer :num_failures
      t.string :code
      t.datetime :code_issued_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
  end

  def down
    [
      :account_sms_codes,
      :account_recovery_codes,
      :account_otp_keys,
      :account_session_keys,
      :account_activity_times,
      :account_password_change_times,
      :account_email_auth_keys,
      :account_lockouts,
      :account_login_failures,
      :account_remember_keys,
      :account_login_change_keys,
      :account_verification_keys,
      :account_jwt_refresh_keys,
      :account_password_reset_keys,
      :account_password_hashes,
      :account_previous_password_hashes,
      :accounts,
      :account_statuses,
    ].each { |table| drop_table(table) }
  end
end
