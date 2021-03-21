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
          return unless defined?(ActiveRecord::Base)

          migration_template "db/migrate/create_rodauth.rb"
        end

        def create_rodauth_initializer
          template "config/initializers/rodauth.rb"
        end

        def create_sequel_initializer
          return unless defined?(ActiveRecord::Base)
          return if defined?(Sequel) && !Sequel::DATABASES.empty?

          template "config/initializers/sequel.rb"
        end

        def create_rodauth_app
          template "app/lib/rodauth_app.rb"
        end

        def create_rodauth_controller
          template "app/controllers/rodauth_controller.rb"
        end

        def create_account_model
          return unless defined?(ActiveRecord::Base)

          template "app/models/account.rb"
        end

        def create_mailer
          template "app/mailers/rodauth_mailer.rb"

          MAILER_VIEWS.each do |view|
            template "app/views/rodauth_mailer/#{view}.text.erb"
          end
        end

        private

        def sequel_uri_scheme
          if RUBY_ENGINE == "jruby"
            "jdbc:#{sequel_jdbc_subadapter}"
          else
            sequel_adapter
          end
        end

        def sequel_adapter
          case activerecord_adapter
          when "sqlite3"         then "sqlite"
          when "oracle_enhanced" then "oracle" # https://github.com/rsim/oracle-enhanced
          when "sqlserver"       then "tinytds" # https://github.com/rails-sqlserver/activerecord-sqlserver-adapter
          else
            activerecord_adapter
          end
        end

        def sequel_jdbc_subadapter
          case activerecord_adapter
          when "sqlite3"         then "sqlite"
          when "oracle_enhanced" then "oracle" # https://github.com/rsim/oracle-enhanced
          when "sqlserver"       then "mssql"
          else
            activerecord_adapter
          end
        end

        def json?
          options[:json]
        end

        def jwt?
          options[:jwt] || Rodauth::Rails.api_only?
        end

        def migration_features
          features = [:base, :reset_password, :verify_account, :verify_login_change]
          features << :remember unless jwt?
          features
        end
      end
    end
  end
end
