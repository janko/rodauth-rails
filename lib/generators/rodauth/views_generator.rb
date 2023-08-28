require "rails/generators/base"

require "#{__dir__}/concerns/configuration"
require "#{__dir__}/concerns/accepts_table"

module Rodauth
  module Rails
    module Generators
      class ViewsGenerator < ::Rails::Generators::Base
        include Concerns::Configuration
        include Concerns::AcceptsTable

        desc "Generate views for specific features.\n\n" \
             "Features supporting views:\n" \
             "=========================================\n" \
             "#{VIEW_CONFIG.keys.sort.map(&:to_s).join "\n"}"

        source_root "#{__dir__}/templates"
        namespace "rodauth:views"

        class_option :features, optional: true, type: :array,
          desc: "Rodauth features to generate views for (login, create_account, reset_password, verify_account etc.)"

        class_option :all, aliases: "-a", type: :boolean,
          desc: "Generates views for all Rodauth features",
          default: false

        class_option :css, type: :string, enum: %w[bootstrap tailwind tailwindcss],
          desc: "CSS framework to generate views for",
          default: "bootstrap"

        def create_views
          validate_features

          views.each do |view|
            copy_file view_location(view), "app/views/#{directory}/#{view}.html.erb" do |content|
              content = content.gsub("rodauth.", "rodauth(:#{configuration_name}).") if configuration_name
              content = content.gsub("rodauth/", "#{directory}/")
              content = form_helpers_compatibility(content) if ActionView.version < Gem::Version.new("5.1")
              content
            end
          end
        end

        private

        def features
          options[:features]
        end

        def views
          selected_features.flat_map { |feature| view_config.fetch(feature) }
        end

        def validate_features
          if (selected_features - view_config.keys).any?
            say "No available view template for feature(s): #{(features - view_config.keys).join(", ")}", :red
            exit(1)
          end
        end

        def selected_features
          if options[:all]
            view_config.keys
          elsif features
            features.map(&:to_sym)
          else
            rodauth_configuration.features & view_config.keys
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
          table_prefix.to_sym if name
        end

        # We need to use the *_tag helpers on versions lower than Rails 5.1.
        def form_helpers_compatibility(content)
          content
            .gsub(/form_with url: (.+) do \|form\|/, 'form_tag \1 do')
            .gsub(/form\.(label|submit)/, '\1_tag')
            .gsub(/form\.(email|password|text|telephone|hidden)_field (\S+), value:/, '\1_field_tag \2,')
            .gsub(/form\.radio_button (\S+), (\S+),/, 'radio_button_tag \1, \2, false,')
            .gsub(/form\.check_box (\S+), (.+) /, 'check_box_tag \1, "t", false, \2 ')
        end

        def view_location(view)
          if tailwind?
            "app/views/rodauth/tailwind/#{view}.html.erb"
          else
            "app/views/rodauth/#{view}.html.erb"
          end
        end

        def tailwind?
          ::Rails.application.config.generators.options[:rails][:template_engine] == :tailwindcss ||
            options[:css]&.downcase&.start_with?("tailwind")
        end
      end
    end
  end
end
