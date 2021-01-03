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

        source_root "#{__dir__}/templates"
        namespace "rodauth:install"

        # The :api option is a Rails-recognized option that always
        # defaults to false, so we make it use our provided default
        # value instead.
        def self.default_value_for_option(name, options)
          name == :api ? options[:default] : super
        end

        class_option :api, type: :boolean, desc: "Generate JSON-only configuration"

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

        def api_only?
          if options.key?(:api)
            options[:api]
          elsif ::Rails.gem_version >= Gem::Version.new("5.0")
            ::Rails.application.config.api_only
          end
        end

        def migration_features
          features = [:base, :reset_password, :verify_account, :verify_login_change]
          features << :remember unless api_only?
          features
        end
      end
    end
  end
end
