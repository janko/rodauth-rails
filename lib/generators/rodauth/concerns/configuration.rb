module Rodauth
  module Rails
    module Generators
      module Concerns
        module Configuration
          # Configuration map that holds the available plugins
          # key: plugin name
          # value: hash that can contain the following keys
          #         *_table(string) => migration table name that can contain format strings: %{plural} and %{singluar}
          #            desc(string) => a custom description for this plugin to be displayed in the command notes
          #           default(bool) => set to true to enable this plugin by default
          #        migrations(bool) => set to false if this plugin does not support migrations
          CONFIGURATION = {
            base: { accounts_table: "%{plural}", default: true, desc: "[PLUGIN] accounts table" },
            remember: { remember_table: "%{singular}_remember_keys", default: true },
            verify_account: { verify_account_table: "%{singular}_verification_keys", default: true },
            verify_login_change: { verify_login_change_table: "%{singular}_login_change_keys", default: true },
            reset_password: { reset_password_table: "%{singular}_password_reset_keys", default: true },
            email_auth: { email_auth_table: "%{singular}_email_auth_keys" },
            otp: { otp_keys_table: "%{singular}_otp_keys" },
            sms_codes: { sms_codes_table: "%{singular}_sms_codes" },
            recovery_codes: { recovery_codes_table: "%{singular}_recovery_codes" },
            webauthn: { webauthn_keys_table: "%{singular}_webauthn_keys", webauthn_user_ids_table: "%{singular}_webauthn_user_ids", webauthn_keys_account_id_column: "%{singular}_id" },
            lockout: { account_login_failures_table: "%{singular}_login_failures", account_lockouts_table: "%{singular}_lockouts" },
            active_sessions: { active_sessions_table: "%{singular}_active_session_keys", active_sessions_account_id_column: "%{singular}_id" },
            account_expiration: { account_activity_table: "%{singular}_activity_times" },
            password_expiration: { password_expiration_table: "%{singular}_password_change_times" },
            single_session: { single_session_table: "%{singular}_session_keys" },
            audit_logging: { audit_logging_table: "%{singular}_authentication_audit_logs", audit_logging_account_id_column: "%{singular}_id" },
            disallow_password_reuse: { previous_password_hash_table: "%{singular}_previous_password_hashes", previous_password_account_id_column: "%{singular}_id" },
            jwt_refresh: { jwt_refresh_token_table: "%{singular}_jwt_refresh_keys", jwt_refresh_token_account_id_column: "%{singular}_id" },
            jwt: { migrations: false },
            json: { migrations: false },
            internal_request: { migrations: false },
          }
        end
      end
    end
  end
end
