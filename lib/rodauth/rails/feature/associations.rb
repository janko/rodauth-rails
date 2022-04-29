module Rodauth
  module Rails
    module Feature
      module Associations
        def associations
          list = []

          features.each do |feature|
            case feature
            when :remember
              list << { name: :remember_key, type: :one, table: remember_table, foreign_key: remember_id_column }
            when :verify_account
              list << { name: :verification_key, type: :one, table: verify_account_table, foreign_key: verify_account_id_column }
            when :reset_password
              list << { name: :password_reset_key, type: :one, table: reset_password_table, foreign_key: reset_password_id_column }
            when :verify_login_change
              list << { name: :login_change_key, type: :one, table: verify_login_change_table, foreign_key: verify_login_change_id_column }
            when :lockout
              list << { name: :lockout, type: :one, table: account_lockouts_table, foreign_key: account_lockouts_id_column }
              list << { name: :login_failure, type: :one, table: account_login_failures_table, foreign_key: account_login_failures_id_column }
            when :email_auth
              list << { name: :email_auth_key, type: :one, table: email_auth_table, foreign_key: email_auth_id_column }
            when :account_expiration
              list << { name: :activity_time, type: :one, table: account_activity_table, foreign_key: account_activity_id_column }
            when :active_sessions
              list << { name: :active_session_keys, type: :many, table: active_sessions_table, foreign_key: active_sessions_account_id_column }
            when :audit_logging
              list << { name: :authentication_audit_logs, type: :many, table: audit_logging_table, foreign_key: audit_logging_account_id_column }
            when :disallow_password_reuse
              list << { name: :previous_password_hashes, type: :many, table: previous_password_hash_table, foreign_key: previous_password_account_id_column }
            when :jwt_refresh
              list << { name: :jwt_refresh_keys, type: :many, table: jwt_refresh_token_table, foreign_key: jwt_refresh_token_account_id_column }
            when :password_expiration
              list << { name: :password_change_time, type: :one, table: password_expiration_table, foreign_key: password_expiration_id_column }
            when :single_session
              list << { name: :session_key, type: :one, table: single_session_table, foreign_key: single_session_id_column }
            when :otp
              list << { name: :otp_key, type: :one, table: otp_keys_table, foreign_key: otp_keys_id_column }
            when :sms_codes
              list << { name: :sms_code, type: :one, table: sms_codes_table, foreign_key: sms_id_column }
            when :recovery_codes
              list << { name: :recovery_codes, type: :many, table: recovery_codes_table, foreign_key: recovery_codes_id_column }
            when :webauthn
              list << { name: :webauthn_user_id, type: :one, table: webauthn_user_ids_table, foreign_key: webauthn_user_ids_account_id_column }
              list << { name: :webauthn_keys, type: :many, table: webauthn_keys_table, foreign_key: webauthn_keys_account_id_column }
            end
          end

          list
        end
      end
    end
  end
end
