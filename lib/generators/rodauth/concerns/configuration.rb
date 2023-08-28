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
            login: { migrations: false, default: true },
            remember: {
              remember_table: '%<singular>s_remember_keys', default: true
            },
            logout: { migrations: false, default: true },
            create_account: {
              accounts_table: '%<plural>s', default: true,
              desc: '[PLUGIN] create account table and model'
            },
            verify_account: {
              verify_account_table: '%<singular>s_verification_keys', default: true
            },
            verify_account_grace_period: { migrations: false, default: true },
            close_account: { migrations: false },
            reset_password: {
              reset_password_table: '%<singular>s_password_reset_keys', default: true
            },
            reset_password_notify: { migrations: false, default: true },
            change_login: { migrations: false, default: true },
            verify_login_change: {
              verify_login_change_table: '%<singular>s_login_change_keys', default: true
            },
            change_password: { migrations: false, default: true },
            change_password_notify: { migrations: false, default: true },
            email_auth: {
              email_auth_table: '%<singular>s_email_auth_keys'
            },
            otp: {
              otp_keys_table: '%<singular>s_otp_keys'
            },
            sms_codes: {
              sms_codes_table: '%<singular>s_sms_codes'
            },
            recovery_codes: {
              recovery_codes_table: '%<singular>s_recovery_codes'
            },
            webauthn: {
              webauthn_keys_table: '%<singular>s_webauthn_keys',
              webauthn_user_ids_table: '%<singular>s_webauthn_user_ids',
              webauthn_keys_account_id_column: '%<singular>s_id'
            },
            lockout: {
              account_login_failures_table: '%<singular>s_login_failures',
              account_lockouts_table: '%<singular>s_lockouts'
            },
            active_sessions: {
              active_sessions_table: '%<singular>s_active_session_keys',
              active_sessions_account_id_column: '%<singular>s_id'
            },
            account_expiration: {
              account_activity_table: '%<singular>s_activity_times'
            },
            password_expiration: {
              password_expiration_table: '%<singular>s_password_change_times'
            },
            single_session: {
              single_session_table: '%<singular>s_session_keys'
            },
            audit_logging: {
              audit_logging_table: '%<singular>s_authentication_audit_logs',
              audit_logging_account_id_column: '%<singular>s_id'
            },
            disallow_password_reuse: {
              previous_password_hash_table: '%<singular>s_previous_password_hashes',
              previous_password_account_id_column: '%<singular>s_id'
            },
            jwt_refresh: {
              jwt_refresh_token_table: '%<singular>s_jwt_refresh_keys',
              jwt_refresh_token_account_id_column: '%<singular>s_id'
            },
            jwt: { migrations: false },
            json: { migrations: false },
            internal_request: { migrations: false }
          }
        end
      end
    end
  end
end
