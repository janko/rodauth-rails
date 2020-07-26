require "rails/generators/base"
require "rails/generators/migration"
require "rails/generators/active_record"

module Rodauth
  module Rails
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        include ::Rails::Generators::Migration

        source_root "#{__dir__}/templates"
        namespace "rodauth:install"

        def create_rodauth_migration
          return unless defined?(ActiveRecord::Base)

          migration_template "db/migrate/create_rodauth.rb", "db/migrate/create_rodauth.rb"
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
          template "lib/rodauth_app.rb"
        end

        def create_rodauth_controller
          template "app/controllers/rodauth_controller.rb"
        end

        def create_account_model
          return unless defined?(ActiveRecord::Base)

          template "app/models/account.rb"
        end

        private

        # required by #migration_template action
        def self.next_migration_number(dirname)
          ActiveRecord::Generators::Base.next_migration_number(dirname)
        end

        def migration_version
          if ActiveRecord.version >= Gem::Version.new("5.0.0")
            "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
          end
        end

        if RUBY_ENGINE == "jruby"
          def sequel_adapter
            case activerecord_adapter
            when "postgresql" then "postgresql"
            when "mysql2"     then "mysql"
            when "sqlite3"    then "sqlite"
            end
          end
        else
          def sequel_adapter
            case activerecord_adapter
            when "postgresql" then "postgres"
            when "mysql2"     then "mysql2"
            when "sqlite3"    then "sqlite"
            end
          end
        end

        def activerecord_adapter
          ActiveRecord::Base.connection_config.fetch(:adapter)
        end
      end
    end
  end
end
