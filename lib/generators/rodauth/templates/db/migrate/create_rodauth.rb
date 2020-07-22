class CreateRodauth < ActiveRecord::Migration<%= migration_version %>
  def change
<% if activerecord_adapter == "postgresql" -%>
    enable_extension "citext"

<% end -%>
    create_table :accounts do |t|
<% case activerecord_adapter -%>
<% when "postgresql" -%>
      t.citext :email, null: false, index: { unique: true, where: "status IN ('verified', 'unverified')" }
<% else -%>
      t.string :email, null: false, index: { unique: true }
<% end -%>
      t.string :status, null: false, default: "verified"
    end

    # Used if storing password hashes in a separate table (default)
    create_table :account_password_hashes do |t|
      t.foreign_key :accounts, column: :id
      t.string :password_hash, null: false
    end

    # Used by the password reset feature
    create_table :account_password_reset_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, null: false
      t.datetime :email_last_sent, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the account verification feature
    create_table :account_verification_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :requested_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :email_last_sent, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    # Used by the verify login change feature
    create_table :account_login_change_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.string :login, null: false
      t.datetime :deadline, null: false
    end

    # Used by the remember me feature
    create_table :account_remember_keys do |t|
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, null: false
    end

    # # Used by the audit logging feature
    # create_table :account_authentication_audit_logs do |t|
    #   t.references :account, null: false
    #   t.datetime :at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    #   t.text :message, null: false
<% case activerecord_adapter -%>
<% when "postgresql" -%>
    #   t.jsonb :metadata
<% when "sqlite3", "mysql2" -%>
    #   t.json :metadata
<% else -%>
    #   t.string :metadata
<% end -%>
    #   t.index [:account_id, :at], name: "audit_account_at_idx"
    #   t.index :at, name: "audit_at_idx"
    # end

    # # Used by the jwt refresh feature
    # create_table :account_jwt_refresh_keys do |t|
    #   t.references :account, null: false
    #   t.string :key, null: false
    #   t.datetime :deadline, null: false
    #   t.index :account_id, name: "account_jwt_rk_account_id_idx"
    # end

    # # Used by the disallow_password_reuse feature
    # create_table :account_previous_password_hashes do |t|
    #   t.references :account
    #   t.string :password_hash, null: false
    # end

    # # Used by the lockout feature
    # create_table :account_login_failures do |t|
    #   t.foreign_key :accounts, column: :id
    #   t.integer :number, null: false, default: 1
    # end
    # create_table :account_lockouts do |t|
    #   t.foreign_key :accounts, column: :id
    #   t.string :key, null: false
    #   t.datetime :deadline, null: false
    #   t.datetime :email_last_sent
    # end

    # # Used by the email auth feature
    # create_table :account_email_auth_keys do |t|
    #   t.foreign_key :accounts, column: :id
    #   t.string :key, null: false
    #   t.datetime :deadline, null: false
    #   t.datetime :email_last_sent, null: false, default: -> { "CURRENT_TIMESTAMP" }
    # end

    # # Used by the password expiration feature
    # create_table :account_password_change_times do |t|
    #   t.foreign_key :accounts, column: :id
    #   t.datetime :changed_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    # end

    # # Used by the account expiration feature
    # create_table :account_activity_times do |t|
    #   t.foreign_key :accounts, column: :id
    #   t.datetime :last_activity_at, null: false
    #   t.datetime :last_login_at, null: false
    #   t.datetime :expired_at
    # end

    # # Used by the single session feature
    # create_table :account_session_keys do |t|
    #   t.foreign_key :accounts, column: :id
    #   t.string :key, null: false
    # end

    # # Used by the active sessions feature
    # create_table :account_active_session_keys, primary_key: [:account_id, :session_id] do |t|
    #   t.references :account
    #   t.string :session_id
    #   t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    #   t.datetime :last_use, null: false, default: -> { "CURRENT_TIMESTAMP" }
    # end

    # # Used by the webauthn feature
    # create_table :account_webauthn_user_ids do |t|
    #   t.foreign_key :accounts, column: :id
    #   t.string :webauthn_id, null: false
    # end
    # create_table :account_webauthn_keys, primary_key: [:account_id, :webauthn_id] do |t|
    #   t.references :account
    #   t.string :webauthn_id
    #   t.string :public_key, null: false
    #   t.integer :sign_count, null: false
    #   t.datetime :last_use, null: false, default: -> { "CURRENT_TIMESTAMP" }
    # end

    # # Used by the otp feature
    # create_table :account_otp_keys do |t|
    #   t.foreign_key :accounts, column: :id
    #   t.string :key, null: false
    #   t.integer :num_failures, null: false, default: 0
    #   t.datetime :last_use, null: false, default: -> { "CURRENT_TIMESTAMP" }
    # end

    # # Used by the recovery codes feature
    # create_table :account_recovery_codes, primary_key: [:id, :code] do |t|
    #   t.integer :id
    #   t.foreign_key :accounts, column: :id
    #   t.string :code
    # end

    # # Used by the sms codes feature
    # create_table :account_sms_codes do |t|
    #   t.foreign_key :accounts, column: :id
    #   t.string :phone_number, null: false
    #   t.integer :num_failures
    #   t.string :code
    #   t.datetime :code_issued_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    # end
  end
end
