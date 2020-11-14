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

        def sequel_adapter
          case activerecord_adapter
          when "postgresql" then "postgres#{"ql" if RUBY_ENGINE == "jruby"}"
          when "mysql2"     then "mysql#{"2" unless RUBY_ENGINE == "jruby"}"
          when "sqlite3"    then "sqlite"
          end
        end

        def activerecord_adapter
          if ActiveRecord::Base.respond_to?(:connection_db_config)
            ActiveRecord::Base.connection_db_config.adapter
          else
            ActiveRecord::Base.connection_config.fetch(:adapter)
          end
        end

        if ::Rails.gem_version >= Gem::Version.new("5.0")
          def migration_version
            "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
          end

          def api_only?
            rails_config.api_only
          end
        else
          def migration_version
            nil
          end

          def api_only?
            false
          end

          def db_migrate_path
            "db/migrate"
          end
        end

        def primary_key_type(key = :id)
          column_type = rails_config.generators.options[:active_record][:primary_key_type]

          return unless column_type

          if key
            ", #{key}: :#{column_type}"
          else
            column_type
          end
        end

        def rails_config
          ::Rails.application.config
        end
      end
    end
  end
end
