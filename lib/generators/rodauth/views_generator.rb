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

        class_option :css, type: :string, enum: %w[bootstrap tailwind tailwindcss],
          desc: "CSS framework to generate views for",
          default: "bootstrap"

        class_option :name, aliases: "-n", type: :string,
          desc: "The configuration name for which to generate views",
          default: nil

        VIEWS = {
          login:               %w[_login_form _login_form_footer login multi_phase_login],
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
          otp_unlock:          %w[otp_unlock otp_unlock_not_available],
          sms_codes:           %w[sms_setup sms_confirm sms_auth sms_request sms_disable],
          recovery_codes:      %w[recovery_codes add_recovery_codes recovery_auth],
          webauthn:            %w[webauthn_setup webauthn_auth webauthn_remove],
          webauthn_autofill:   %w[webauthn_autofill],
          confirm_password:    %w[confirm_password],
        }

        def create_views
          return unless validate_features

          views.each do |view|
            copy_file view_location(view), "app/views/#{directory}/#{view}.html.erb" do |content|
              content = content.gsub("rodauth.", "rodauth(:#{configuration_name}).") if configuration_name
              content = content.gsub("rodauth/", "#{directory}/")
              content
            end
          end
        end

        private

        def views
          features.flat_map { |feature| VIEWS.fetch(feature) }
        end

        def validate_features
          if (features - VIEWS.keys).any?
            say "No available view template for feature(s): #{(features - VIEWS.keys).join(", ")}", :error
            false
          else
            true
          end
        end

        def features
          if options[:all]
            VIEWS.keys
          elsif selected_features
            selected_features.map(&:to_sym)
          else
            rodauth_configuration.features & VIEWS.keys
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

        def view_location(view)
          if tailwind?
            "app/views/rodauth/tailwind/#{view}.html.erb"
          else
            "app/views/rodauth/#{view}.html.erb"
          end
        end

        def tailwind?
          ::Rails.configuration.generators.options[:rails][:template_engine] == :tailwindcss ||
            options[:css]&.downcase&.start_with?("tailwind")
        end
      end
    end
  end
end
