require "rails/generators/base"
require "securerandom"

module Rodauth
  module Rails
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        SEQUEL_ADAPTERS = {
          "postgresql"      => RUBY_ENGINE == "jruby" ? "postgresql" : "postgres",
          "mysql2"          => RUBY_ENGINE == "jruby" ? "mysql" : "mysql2",
          "sqlite3"         => "sqlite",
          "oracle_enhanced" => "oracle",
          "sqlserver"       => RUBY_ENGINE == "jruby" ? "mssql" : "tinytds",
        }

        MAILER_VIEWS = %w[
          email_auth
          password_changed
          reset_password
          unlock_account
          verify_account
          verify_login_change
        ]

        source_root "#{__dir__}/templates"
        namespace "rodauth:install"

        class_option :argon2, type: :boolean, desc: "Use Argon2 for password hashing"
        class_option :json, type: :boolean, desc: "Configure JSON support"
        class_option :jwt, type: :boolean, desc: "Configure JWT support"

        def create_rodauth_migration
          invoke "rodauth:migration", migration_features, name: "create_rodauth"
        end

        def create_rodauth_initializer
          template "config/initializers/rodauth.rb"
        end

        def create_rodauth_app
          template "app/misc/rodauth_app.rb"
          template "app/misc/rodauth_main.rb"
        end

        def create_rodauth_controller
          template "app/controllers/rodauth_controller.rb"
        end

        def create_account_model
          template "app/models/account.rb"
        end

        def create_mailer
          return unless defined?(ActionMailer)

          template "app/mailers/rodauth_mailer.rb"

          MAILER_VIEWS.each do |view|
            copy_file "app/views/rodauth_mailer/#{view}.text.erb"
          end
        end

        def create_fixtures
          test_unit_options = ::Rails.application.config.generators.options[:test_unit]
          if test_unit_options[:fixture] && test_unit_options[:fixture_replacement].nil?
            if ::Rails.application.config.generators.options[:rails][:test_framework] == :rspec
              template "test/fixtures/accounts.yml", "spec/fixtures/accounts.yml"
            else
              template "test/fixtures/accounts.yml", "test/fixtures/accounts.yml"
            end
          end
        end

        def show_instructions
          readme "INSTRUCTIONS" if behavior == :invoke
        end

        private

        def migration_features
          features = ["base", "reset_password", "verify_account", "verify_login_change"]
          features << "remember" unless jwt?
          features
        end

        def json?
          options[:json] || api_only? && session_store? && !options[:jwt]
        end

        def jwt?
          options[:jwt] || api_only? && !session_store? && !options[:json]
        end

        def argon2?
          options[:argon2]
        end

        def sequel_activerecord_integration?
          defined?(ActiveRecord::Railtie) &&
            (!defined?(Sequel) || Sequel::DATABASES.empty?)
        end

        def session_store?
          !!::Rails.application.config.session_store
        end

        def api_only?
          Rodauth::Rails.api_only?
        end

        def sequel_adapter
          SEQUEL_ADAPTERS[activerecord_adapter] || activerecord_adapter
        end

        def activerecord_adapter
          if ActiveRecord::Base.respond_to?(:connection_db_config)
            ActiveRecord::Base.connection_db_config.adapter
          else
            ActiveRecord::Base.connection_config.fetch(:adapter)
          end
        end
      end
    end
  end
end
