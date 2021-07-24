module Rodauth
  module Rails
    class Model
      class Associations
        attr_reader :rodauth

        def self.call(rodauth)
          new(rodauth).call
        end

        def initialize(rodauth)
          @rodauth = rodauth
        end

        def call
          rodauth.features
            .select { |feature| respond_to?(feature, true) }
            .flat_map { |feature| send(feature) }
        end

        private

        def remember
          {
            name: :remember_key,
            type: :has_one,
            table: rodauth.remember_table,
            foreign_key: rodauth.remember_id_column,
          }
        end

        def verify_account
          {
            name: :verification_key,
            type: :has_one,
            table: rodauth.verify_account_table,
            foreign_key: rodauth.verify_account_id_column,
          }
        end

        def reset_password
          {
            name: :password_reset_key,
            type: :has_one,
            table: rodauth.reset_password_table,
            foreign_key: rodauth.reset_password_id_column,
          }
        end

        def verify_login_change
          {
            name: :login_change_key,
            type: :has_one,
            table: rodauth.verify_login_change_table,
            foreign_key: rodauth.verify_login_change_id_column,
          }
        end

        def lockout
          [
            {
              name: :lockout,
              type: :has_one,
              table: rodauth.account_lockouts_table,
              foreign_key: rodauth.account_lockouts_id_column,
            },
            {
              name: :login_failure,
              type: :has_one,
              table: rodauth.account_login_failures_table,
              foreign_key: rodauth.account_login_failures_id_column,
            }
          ]
        end

        def email_auth
          {
            name: :email_auth_key,
            type: :has_one,
            table: rodauth.email_auth_table,
            foreign_key: rodauth.email_auth_id_column,
          }
        end

        def account_expiration
          {
            name: :activity_time,
            type: :has_one,
            table: rodauth.account_activity_table,
            foreign_key: rodauth.account_activity_id_column,
          }
        end

        def active_sessions
          {
            name: :active_session_keys,
            type: :has_many,
            table: rodauth.active_sessions_table,
            foreign_key: rodauth.active_sessions_account_id_column,
          }
        end

        def audit_logging
          {
            name: :authentication_audit_logs,
            type: :has_many,
            table: rodauth.audit_logging_table,
            foreign_key: rodauth.audit_logging_account_id_column,
            dependent: nil,
          }
        end

        def disallow_password_reuse
          {
            name: :previous_password_hashes,
            type: :has_many,
            table: rodauth.previous_password_hash_table,
            foreign_key: rodauth.previous_password_account_id_column,
          }
        end

        def jwt_refresh
          {
            name: :jwt_refresh_keys,
            type: :has_many,
            table: rodauth.jwt_refresh_token_table,
            foreign_key: rodauth.jwt_refresh_token_account_id_column,
          }
        end

        def password_expiration
          {
            name: :password_change_time,
            type: :has_one,
            table: rodauth.password_expiration_table,
            foreign_key: rodauth.password_expiration_id_column,
          }
        end

        def single_session
          {
            name: :session_key,
            type: :has_one,
            table: rodauth.single_session_table,
            foreign_key: rodauth.single_session_id_column,
          }
        end

        def otp
          {
            name: :otp_key,
            type: :has_one,
            table: rodauth.otp_keys_table,
            foreign_key: rodauth.otp_keys_id_column,
          }
        end

        def sms_codes
          {
            name: :sms_code,
            type: :has_one,
            table: rodauth.sms_codes_table,
            foreign_key: rodauth.sms_id_column,
          }
        end

        def recovery_codes
          {
            name: :recovery_codes,
            type: :has_many,
            table: rodauth.recovery_codes_table,
            foreign_key: rodauth.recovery_codes_id_column,
          }
        end

        def webauthn
          [
            {
              name: :webauthn_user_id,
              type: :has_one,
              table: rodauth.webauthn_user_ids_table,
              foreign_key: rodauth.webauthn_user_ids_account_id_column,
            },
            {
              name: :webauthn_keys,
              type: :has_many,
              table: rodauth.webauthn_keys_table,
              foreign_key: rodauth.webauthn_keys_account_id_column,
            }
          ]
        end
      end
    end
  end
end
