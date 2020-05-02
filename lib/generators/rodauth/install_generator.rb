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

        def copy_rodauth_initializer
          template "config/initializers/rodauth.rb"
        end

        def copy_sequel_initializer
          return unless defined?(ActiveRecord::Base)
          return unless %w[postgresql mysql2 sqlite3].include?(adapter)

          template "config/initializers/sequel.rb"
        end

        def copy_migration
          return unless defined?(ActiveRecord::Base)

          migration_template "db/migrate/create_rodauth.rb", "db/migrate/create_rodauth.rb"
        end

        def copy_app
          template "lib/rodauth_app.rb"
        end

        def copy_model
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

        def adapter
          ActiveRecord::Base.connection_config.fetch(:adapter)
        end
      end
    end
  end
end
