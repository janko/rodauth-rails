require "rails/generators/base"
require "rails/generators/active_record/migration"
require "generators/rodauth/migration_helpers"

module Rodauth
  module Rails
    module Generators
      class MigrationGenerator < ::Rails::Generators::Base
        include ::ActiveRecord::Generators::Migration
        include MigrationHelpers

        source_root "#{__dir__}/templates"
        namespace "rodauth:migration"

        argument :features, optional: true, type: :array,
          desc: "Rodauth features to create tables for (otp, sms_codes, single_session, account_expiration etc.)",
          default: %w[]

        class_option :name, optional: true, type: :string,
          desc: "Name of the generated migration file"

        def create_rodauth_migration
          return unless defined?(ActiveRecord::Railtie)
          return if features.empty?

          migration_template "db/migrate/create_rodauth.rb", "#{migration_name}.rb"
        end

        def migration_features
          features
        end

        def migration_name
          options[:name] || "create_rodauth_#{features.join("_")}"
        end
      end
    end
  end
end
