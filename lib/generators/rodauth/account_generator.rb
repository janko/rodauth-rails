require 'rails/generators/base'
require 'securerandom'

require "#{__dir__}/concerns/account_selector"
require "#{__dir__}/concerns/feature_selector"

module Rodauth
  module Rails
    module Generators
      class AccountGenerator < ::Rails::Generators::Base
        include Concerns::AccountSelector
        include Concerns::FeatureSelector

        source_root "#{__dir__}/templates"
        namespace 'rodauth:account'

        desc "Generate a rodauth-rails account.\n\n" \
             "Configures a basic set of features as well as migrations, a model, mailer and views."

        def create_rodauth_app
          template 'app/misc/rodauth_account_plugin.rb', "app/misc/rodauth_#{table_prefix}_plugin.rb"
        end

        def configure_rodauth_plugin
          plugin_name = indent(
            "configure ::Rodauth#{table_prefix.classify}Plugin#{", :#{table_prefix}" unless primary?}\n", 2
          )
          gsub_file 'app/misc/rodauth_app.rb', /.*# configure RodauthMain\n/, ''
          insert_into_file 'app/misc/rodauth_app.rb', plugin_name, after: "# auth configuration\n"
        end

        def configure_rodauth_plugin_load_route
          route_config = indent("r.rodauth#{"(:#{table_prefix})" unless primary?}\n", 4)
          gsub_file 'app/misc/rodauth_app.rb', /.*# r\.rodauth\n/, ''
          insert_into_file 'app/misc/rodauth_app.rb', route_config, after: "# auth route configuration\n"
        end

        def configure_rodauth_plugin_load_memory
          plugin_config = indent(
            "rodauth#{"(:#{table_prefix})" unless primary?}.load_memory # autologin remembered #{table}\n", 4
          )
          if remember?
            gsub_file 'app/misc/rodauth_app.rb', /.*# rodauth\.load_memory.*\n/, ''
            insert_into_file 'app/misc/rodauth_app.rb', plugin_config, after: "# plugin route configuration\n"
          else
            gsub_file 'app/misc/rodauth_app.rb', plugin_config, ''
            gsub_file 'app/misc/rodauth_app.rb', /.*# rodauth\.load_memory.*\n/, ''
            in_root do
              unless File.read('app/misc/rodauth_app.rb').match /.*\.load_memory # autologin/
                insert_into_file 'app/misc/rodauth_app.rb', indent("# rodauth.load_memory # autologin remembered users\n", 4),
                                after: "# plugin route configuration\n"
              end
            end
          end
        end

        def create_rodauth_controller
          dest = "app/controllers/#{table_prefix}/rodauth_controller.rb" unless primary?
          template 'app/controllers/rodauth_controller.rb', dest
        end

        def generate_rodauth_migration
          return if selected_migration_features.empty?

          invoke 'rodauth:migration', [table], features: selected_migration_features,
                                               name: kitchen_sink? ? 'rodauth_kitchen_sink' : nil,
                                               migration_name: options[:migration_name]
        end

        def create_account_model
          return unless base?

          template 'app/models/account.rb', "app/models/#{table_prefix}.rb"
        end

        def create_mailer
          return unless mails?

          template 'app/mailers/rodauth_mailer.rb', "app/mailers/rodauth_#{table_prefix}_mailer.rb"
          directory 'app/views/rodauth_mailer', "app/views/rodauth_#{table_prefix}_mailer"
        end

        def install_required_gems
          Bundler.with_unbundled_env do
            # this is required for jwt
            # if it is not installed, the subsequent view generation fails, since it actually loads rails
            run "bundle add jwt" if jwt? || jwt_refresh?
          end
        end

        def create_views
          return if only_json? || selected_view_features.empty?

          account_name = primary? ? nil : table_prefix
          # Use generate here because invoke spawns in the same process
          # Unfortunately, during the generation process, some new files are created which are not currently loaded,
          #   causing an error when it attempts to load the rodauth config.
          # Generate spawns a separate process which loads the new files and ensures it works correctly
          generate 'rodauth:views', account_name, "--features", *selected_view_features
        end

        def create_fixtures
          generator_options = ::Rails.application.config.generators.options
          unless generator_options[:test_unit][:fixture] && generator_options[:test_unit][:fixture_replacement].nil?
            return
          end

          test_dir = generator_options[:rails][:test_framework] == :rspec ? 'spec' : 'test'
          template 'test/fixtures/accounts.yml', "#{test_dir}/fixtures/#{table_prefix.pluralize}.yml"
        end

        private

        def only_json?
          ::Rails.application.config.api_only || !::Rails.application.config.session_store || options[:api_only]
        end
      end
    end
  end
end
