require "rails/generators/base"

module Rodauth
  module Rails
    module Generators
      class ViewsGenerator < ::Rails::Generators::Base
        source_root "#{__dir__}/templates"
        namespace "rodauth:views"

        argument :selected_features, optional: true, type: :array,
          desc: "Rodauth features to generate views for (login, create_account, reset_password, verify_account etc.)"

        class_option :all, aliases: "-a", type: :boolean,
          desc: "Generates views for all Rodauth features",
          default: false

        class_option :name, aliases: "-n", type: :string,
          desc: "The configuration name for which to generate views",
          default: nil

        VIEWS = {
          login:               %w[_login_form _login_form_footer _login_form_header login multi_phase_login],
          create_account:      %w[create_account],
          logout:              %w[logout],
          reset_password:      %w[reset_password_request reset_password],
          remember:            %w[remember],
          change_login:        %w[change_login],
          change_password:     %w[change_password],
          close_account:       %w[close_account],
          email_auth:          %w[_email_auth_request_form email_auth],
          verify_account:      %w[verify_account_resend verify_account],
          verify_login_change: %w[verify_login_change],
          lockout:             %w[unlock_account_request unlock_account],
          two_factor_base:     %w[two_factor_manage two_factor_auth two_factor_disable],
          otp:                 %w[otp_setup otp_auth otp_disable],
          sms_codes:           %w[sms_setup sms_confirm sms_auth sms_request sms_disable],
          recovery_codes:      %w[recovery_codes add_recovery_codes recovery_auth],
          webauthn:            %w[webauthn_setup webauthn_auth webauthn_remove],
        }

        DEPENDENCIES = {
          otp:            :two_factor_base,
          sms_codes:      :two_factor_base,
          recovery_codes: :two_factor_base,
          webauthn:       :two_factor_base,
        }

        def create_views
          views = features.inject([]) do |list, feature|
            list |= VIEWS[feature] || []
            list |= VIEWS[DEPENDENCIES[feature]] || []
          end

          views.each do |view|
            copy_file "app/views/rodauth/#{view}.html.erb", "app/views/#{directory}/#{view}.html.erb" do |content|
              content = content.gsub("rodauth.", "rodauth(:#{configuration_name}).") if configuration_name
              content = content.gsub("rodauth/", "#{directory}/")
              content = form_helpers_compatibility(content) if ActionView.version < Gem::Version.new("5.1")
              content
            end
          end
        end

        private

        def features
          if options[:all]
            VIEWS.keys
          elsif selected_features
            selected_features.map(&:to_sym)
          else
            rodauth_configuration.features
          end
        end

        def directory
          if controller.abstract?
            fail Error, "no controller configured for configuration: #{configuration_name.inspect}"
          end

          controller.controller_path
        end

        def controller
          rodauth_configuration.allocate.rails_controller
        end

        def rodauth_configuration
          Rodauth::Rails.app.rodauth!(configuration_name)
        end

        def configuration_name
          options[:name]&.to_sym
        end

        # We need to use the *_tag helpers on versions lower than Rails 5.1.
        def form_helpers_compatibility(content)
          content
            .gsub(/form_with url: (.+) do \|form\|/, 'form_tag \1 do')
            .gsub(/form\.(label|submit)/, '\1_tag')
            .gsub(/form\.(email|password|text|telephone|hidden)_field (\S+), value:/, '\1_field_tag \2,')
            .gsub(/form\.radio_button (\S+), (\S+)/, 'radio_button_tag \1, \2, false')
            .gsub(/form\.check_box (\S+), (.+) /, 'check_box_tag \1, "t", false, \2 ')
        end
      end
    end
  end
end
