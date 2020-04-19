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

        def copy_initializer
          template "config/initializers/rodauth.rb"
        end

        def copy_migration
          migration_template "db/migrate/create_rodauth.rb", "db/migrate/create_rodauth.rb",
            migration_version: migration_version, adapter: adapter
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
          "[#{::Rails::VERSION::MAJOR}.#{::Rails::VERSION::MINOR}]"
        end

        def adapter
          config = ActiveRecord::Base.configurations[::Rails.env]
          config.fetch("adapter")
        end
      end
    end
  end
end
