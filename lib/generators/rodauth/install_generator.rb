require "rails/generators/base"
require "rails/generators/active_record/migration"

require "securerandom"

module Rodauth
  module Rails
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        include ::ActiveRecord::Generators::Migration

        source_root "#{__dir__}/templates"
        namespace "rodauth:install"

        def create_rodauth_migration
          return unless defined?(ActiveRecord::Base)

          migration_template "db/migrate/create_rodauth.rb", File.join(db_migrate_path, "create_rodauth.rb")
        end

        def create_rodauth_initializer
          template "config/initializers/rodauth.rb"
        end

        def create_sequel_initializer
          return unless defined?(ActiveRecord::Base)
          return unless %w[postgresql mysql2 sqlite3].include?(activerecord_adapter)
          return if defined?(Sequel) && !Sequel::DATABASES.empty?

          template "config/initializers/sequel.rb"
        end

        def create_rodauth_app
          template "app/lib/rodauth_app.rb"
        end

        def create_rodauth_controller
          return if api_only?

          template "app/controllers/rodauth_controller.rb"
        end

        def create_account_model
          return unless defined?(ActiveRecord::Base)

          template "app/models/account.rb"
        end

        private

        def db_migrate_path
          return "db/migrate" unless ActiveRecord.version >= Gem::Version.new("5.0")

          super
        end

        def migration_version
          if ActiveRecord.version >= Gem::Version.new("5.0")
            "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
          end
        end

        def sequel_adapter
          case activerecord_adapter
          when "postgresql" then "postgres#{"ql" if RUBY_ENGINE == "jruby"}"
          when "mysql2"     then "mysql#{"2" unless RUBY_ENGINE == "jruby"}"
          when "sqlite3"    then "sqlite"
          end
        end

        def activerecord_adapter
          ActiveRecord::Base.connection_config.fetch(:adapter)
        end

        def api_only?
          return false if ::Rails.gem_version < Gem::Version.new("5.0")

          ::Rails.application.config.api_only
        end
      end
    end
  end
end
