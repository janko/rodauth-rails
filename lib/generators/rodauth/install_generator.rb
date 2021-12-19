require "rails/generators/base"
require "rails/generators/active_record/migration"
require "generators/rodauth/migration_helpers"
require "securerandom"

module Rodauth
  module Rails
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        include ::ActiveRecord::Generators::Migration
        include MigrationHelpers

        if RUBY_ENGINE == "jruby"
          SEQUEL_ADAPTERS = {
            "sqlite3"         => "sqlite",
            "oracle_enhanced" => "oracle", # https://github.com/rsim/oracle-enhanced
            "sqlserver"       => "mssql",
          }
        else
          SEQUEL_ADAPTERS = {
            "sqlite3"         => "sqlite",
            "oracle_enhanced" => "oracle", # https://github.com/rsim/oracle-enhanced
            "sqlserver"       => "tinytds", # https://github.com/rails-sqlserver/activerecord-sqlserver-adapter
          }
        end

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

        class_option :json, type: :boolean, desc: "Configure JSON support"
        class_option :jwt, type: :boolean, desc: "Configure JWT support"

        def create_rodauth_migration
          return unless defined?(ActiveRecord::Railtie)

          migration_template "db/migrate/create_rodauth.rb"
        end

        def create_rodauth_initializer
          template "config/initializers/rodauth.rb"
        end

        def create_sequel_initializer
          return unless defined?(ActiveRecord::Railtie)
          return if defined?(Sequel) && !Sequel::DATABASES.empty?

          template "config/initializers/sequel.rb"
        end

        def create_rodauth_app
          template "app/misc/rodauth_app.rb"
          template "app/misc/rodauth_main.rb"
        end

        def create_rodauth_controller
          template "app/controllers/rodauth_controller.rb"
        end

        def create_account_model
          return unless defined?(ActiveRecord::Railtie)

          template "app/models/account.rb"
        end

        def create_mailer
          template "app/mailers/rodauth_mailer.rb"

          MAILER_VIEWS.each do |view|
            copy_file "app/views/rodauth_mailer/#{view}.text.erb"
          end
        end

        def show_instructions
          readme "INSTRUCTIONS" if behavior == :invoke
        end

        private

        def migration_features
          features = [:base, :reset_password, :verify_account, :verify_login_change]
          features << :remember unless jwt?
          features
        end

        def json?
          options[:json] || api_only? && session_store? && !options[:jwt]
        end

        def jwt?
          options[:jwt] || api_only? && !session_store? && !options[:json]
        end

        def session_store?
          !!::Rails.application.config.session_store
        end

        def api_only?
          Rodauth::Rails.api_only?
        end

        def sequel_uri_scheme
          scheme = SEQUEL_ADAPTERS[activerecord_adapter] || activerecord_adapter
          scheme = "jdbc:#{scheme}" if RUBY_ENGINE == "jruby"
          scheme
        end
      end
    end
  end
end
