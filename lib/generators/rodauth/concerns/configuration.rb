module Rodauth
  module Rails
    module Generators
      module Concerns
        module Configuration
          # Configuration map for the supported plugins
          # key: plugin name
          # value: hash that can contain the following keys
          #           feature(bool) => enabled in the account plugin when selected. default: true.
          #           default(bool) => enable this plugin by default
          #            desc(string) => description for this plugin to be displayed in the cli help notes
          #        migrations(Hash) => map of table override setter to table name.
          #                            table name can contain the format strings: %{plural} and %{singluar}
          #            views(array) => a list of views to generate
          CONFIGURATION = {
            base: {
              default: true,
              feature: false,
              desc: '[CONFIG] create account table and model',
              migrations: {
                accounts_table: '%<plural>s'
              }
            },
            login: {
              default: true,
              views: %w[_login_form _login_form_footer login multi_phase_login]
            },
            remember: {
              default: true,
              views: %w[remember],
              migrations: {
                remember_table: '%<singular>s_remember_keys'
              }
            },
            logout: {
              default: true,
              views: %w[logout]
            },
            create_account: {
              default: true,
              views: %w[create_account]
            },
            verify_account: {
              default: true,
              views: %w[verify_account_resend verify_account],
              migrations: {
                verify_account_table: '%<singular>s_verification_keys'
              }
            },
            verify_account_grace_period: { default: true },
            close_account: {
              views: %w[close_account]
            },
            reset_password: {
              default: true,
              views: %w[reset_password_request reset_password],
              migrations: {
                reset_password_table: '%<singular>s_password_reset_keys'
              }
            },
            reset_password_notify: { default: true },
            change_login: {
              default: true,
              views: %w[change_login]
            },
            verify_login_change: {
              default: true,
              views: %w[verify_login_change],
              migrations: {
                verify_login_change_table: '%<singular>s_login_change_keys'
              }
            },
            change_password: {
              default: true,
              views: %w[change_password]
            },
            change_password_notify: {
              default: true
            },
            email_auth: {
              views: %w[_email_auth_request_form email_auth],
              migrations: {
                email_auth_table: '%<singular>s_email_auth_keys'
              }
            },
            otp: {
              views: %w[otp_setup otp_auth otp_disable],
              migrations: {
                otp_keys_table: '%<singular>s_otp_keys'
              }
            },
            sms_codes: {
              views: %w[sms_setup sms_confirm sms_auth sms_request sms_disable],
              migrations: {
                sms_codes_table: '%<singular>s_sms_codes'
              }
            },
            recovery_codes: {
              views: %w[recovery_codes add_recovery_codes recovery_auth],
              migrations: {
                recovery_codes_table: '%<singular>s_recovery_codes'
              }
            },
            webauthn: {
              views: %w[webauthn_setup webauthn_auth webauthn_remove],
              migrations: {
                webauthn_keys_table: '%<singular>s_webauthn_keys',
                webauthn_user_ids_table: '%<singular>s_webauthn_user_ids',
                webauthn_keys_account_id_column: '%<singular>s_id'
              }
            },
            webauthn_autofill: {
              views: %w[webauthn_autofill]
            },
            lockout: {
              views: %w[unlock_account_request unlock_account],
              migrations: {
                account_login_failures_table: '%<singular>s_login_failures',
                account_lockouts_table: '%<singular>s_lockouts'
              }
            },
            active_sessions: {
              migrations: {
                active_sessions_table: '%<singular>s_active_session_keys',
                active_sessions_account_id_column: '%<singular>s_id'
              }
            },
            account_expiration: {
              migrations: {
                account_activity_table: '%<singular>s_activity_times'
              }
            },
            password_expiration: {
              migrations: {
                password_expiration_table: '%<singular>s_password_change_times'
              }
            },
            single_session: {
              migrations: {
                single_session_table: '%<singular>s_session_keys'
              }
            },
            audit_logging: {
              migrations: {
                audit_logging_table: '%<singular>s_authentication_audit_logs',
                audit_logging_account_id_column: '%<singular>s_id'
              }
            },
            disallow_password_reuse: {
              migrations: {
                previous_password_hash_table: '%<singular>s_previous_password_hashes',
                previous_password_account_id_column: '%<singular>s_id'
              }
            },
            jwt_refresh: {
              migrations: {
                jwt_refresh_token_table: '%<singular>s_jwt_refresh_keys',
                jwt_refresh_token_account_id_column: '%<singular>s_id'
              }
            },
            jwt: {},
            json: {},
            internal_request: {},
            # TODO: this is an outlier.
            # Identify the 2fa plugins and figure out how to import this there.
            two_factor_base: {
              feature: false,
              views: %w[two_factor_manage two_factor_auth two_factor_disable]
            }
          }.freeze

          FEATURE_CONFIG = CONFIGURATION.select { |_k, v| v[:feature] != false }
                                       .freeze

          MIGRATION_CONFIG = CONFIGURATION.select { |_k, v| v[:migrations] }
                                          .map { |k, v| [k, v[:migrations]] }
                                          .to_h
                                          .freeze

          VIEW_CONFIG = CONFIGURATION.select { |_k, v| v[:views] }
                                     .map { |k, v| [k, v[:views]] }
                                     .to_h
                                     .freeze

          private

          def configuration
            CONFIGURATION
          end

          def feature_config
            FEATURE_CONFIG
          end

          def migration_config
            MIGRATION_CONFIG
          end

          def view_config
            VIEW_CONFIG
          end
        end
      end
    end
  end
end
