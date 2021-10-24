require "rails/generators/base"

module Rodauth
  module Rails
    module Generators
      class ViewsGenerator < ::Rails::Generators::Base
        source_root "#{__dir__}/templates"
        namespace "rodauth:views"

        argument :features, optional: true, type: :array,
          desc: "Rodauth features to generate views for (login, create_account, reset_password, verify_account etc.)",
          default: %w[login logout create_account verify_account reset_password change_password change_login verify_login_change close_account]

        class_option :all, aliases: "-a", type: :boolean,
          desc: "Generates views for all Rodauth features",
          default: false

        class_option :name, aliases: "-n", type: :string,
          desc: "The configuration name for which to generate views",
          default: nil

        VIEWS = {
          login: %w[
            _field _field_error _login_field _login_display _password_field
            _submit _login_form _login_form_footer _login_form_header login
            multi_phase_login
          ],
          create_account: %w[
            _field _field_error _login_field _login_confirm_field
            _password_field _password_confirm_field _submit create_account
          ],
          logout: %w[
            _submit logout
          ],
          reset_password: %w[
            _field _field_error _login_field _login_hidden_field
            _password_field _password_confirm_field _submit
            reset_password_request reset_password
          ],
          remember: %w[
            _submit remember
          ],
          change_login: %w[
            _field _field_error _login_field _login_confirm_field
            _password_field _submit change_login
          ],
          change_password: %w[
            _field _field_error _password_field _new_password_field
            _password_confirm_field _submit change_password
          ],
          close_account: %w[
            _field _field_error _password_field _submit close_account
          ],
          email_auth: %w[
            _login_hidden_field _submit _email_auth_request_form email_auth
          ],
          verify_account: %w[
            _field _field_error _login_hidden_field _login_field _submit
            verify_account_resend verify_account
          ],
          verify_login_change: %w[
            _submit verify_login_change
          ],
          lockout: %w[
            _login_hidden_field _submit unlock_account_request unlock_account
          ],
          active_sessions: %w[
            _global_logout_field
          ],
          two_factor_base: %w[
            _field _field_error _password_field _submit
            two_factor_manage two_factor_auth two_factor_disable
          ],
          otp: %w[
            _field _field_error _otp_auth_code_field _password_field _submit
            otp_setup otp_auth otp_disable
          ],
          sms_codes: %w[
            _field _field_error _sms_code_field _sms_phone_field
            _password_field _submit
            sms_setup sms_confirm sms_auth sms_request sms_disable
          ],
          recovery_codes: %w[
            _field _field_error _recovery_code_field
            recovery_codes add_recovery_codes recovery_auth
          ],
          webauthn: %w[
            _field _field_error _login_hidden_field _password_field _submit
            webauthn_setup webauthn_auth webauthn_remove
          ]
        }

        DEPENDENCIES = {
          active_sessions: :logout,
          otp:             :two_factor_base,
          sms_codes:       :two_factor_base,
          recovery_codes:  :two_factor_base,
          webauthn:        :two_factor_base,
        }

        def create_views
          if options[:all]
            features = VIEWS.keys
          else
            features = self.features.map(&:to_sym)
          end

          views = features.inject([]) do |list, feature|
            list |= VIEWS[feature] || []
            list |= VIEWS[DEPENDENCIES[feature]] || []
          end

          views.each do |view|
            template "app/views/rodauth/#{view}.html.erb",
              "app/views/#{directory}/#{view}.html.erb"
          end
        end

        def directory
          if controller.abstract?
            fail Error, "no controller configured for configuration: #{configuration_name.inspect}"
          end

          controller.controller_path
        end

        def rodauth
          "rodauth#{"(:#{configuration_name})" if configuration_name}"
        end

        def controller
          rodauth = Rodauth::Rails.app.rodauth!(configuration_name)
          rodauth.allocate.rails_controller
        end

        def configuration_name
          options[:name]&.to_sym
        end
      end
    end
  end
end
