require "rails/generators/base"
require "rails/generators/active_record/migration"
require "erb"

module Rodauth
  module Rails
    module Generators
      class MigrationGenerator < ::Rails::Generators::Base
        source_root "#{__dir__}/templates"
        namespace "rodauth:migration"

        argument :features, optional: true, type: :array,
          desc: "Rodauth features to create tables for (otp, sms_codes, single_session, account_expiration etc.)",
          default: %w[]

        class_option :prefix, optional: true, type: :string,
          desc: "Change prefix for generated tables (default: account)"

        class_option :name, optional: true, type: :string,
          desc: "Name of the generated migration file"

        def create_rodauth_migration
          validate_features or return

          migration_template "db/migrate/create_rodauth.rb", File.join(db_migrate_path, "#{migration_name}.rb")
        end

        private

        def migration_name
          options[:name] || ["create_rodauth", *options[:prefix], *features].join("_")
        end

        def migration_content
          features
            .map { |feature| File.read(migration_chunk(feature)) }
            .map { |content| erb_eval(content) }
            .join("\n")
            .indent(4)
        end

        def erb_eval(content)
          if ERB.version[/\d+\.\d+\.\d+/].to_s >= "2.2.0"
            ERB.new(content, trim_mode: "-").result(binding)
          else
            ERB.new(content, 0, "-").result(binding)
          end
        end

        def migration_chunk(feature)
          "#{MIGRATION_DIR}/#{feature}.erb"
        end

        def validate_features
          if features.empty?
            say "No features specified!", :yellow
            false
          elsif (features - valid_features).any?
            say "No available migration for feature(s): #{(features - valid_features).join(", ")}", :red
            false
          else
            true
          end
        end

        def valid_features
          Dir["#{MIGRATION_DIR}/*.erb"].map { |filename| File.basename(filename, ".erb") }
        end

        def table_prefix
          options[:prefix]&.singularize || "account"
        end

        if defined?(::ActiveRecord::Railtie) # Active Record
          include ::ActiveRecord::Generators::Migration

          MIGRATION_DIR = "#{__dir__}/migration/active_record"

          def db_migrate_path
            return "db/migrate" unless ActiveRecord.version >= Gem::Version.new("5.0")

            super
          end

          def migration_version
            return unless ActiveRecord.version >= Gem::Version.new("5.0")

            "[#{ActiveRecord::Migration.current_version}]"
          end

          def activerecord_adapter
            if ActiveRecord::Base.respond_to?(:connection_db_config)
              ActiveRecord::Base.connection_db_config.adapter
            else
              ActiveRecord::Base.connection_config.fetch(:adapter)
            end
          end

          def primary_key_type(key = :id)
            generators  = ::Rails.application.config.generators
            column_type = generators.options[:active_record][:primary_key_type]

            if key
              ", #{key}: :#{column_type}" if column_type
            else
              column_type || default_primary_key_type
            end
          end

          def default_primary_key_type
            if ActiveRecord.version >= Gem::Version.new("5.1") && activerecord_adapter != "sqlite3"
              :bigint
            else
              :integer
            end
          end

          def current_timestamp
            if ActiveRecord.version >= Gem::Version.new("5.0")
              %(-> { "#{current_timestamp_literal}" })
            else
              %(OpenStruct.new(quoted_id: "#{current_timestamp_literal}"))
            end
          end

          # Active Record 7+ sets default precision to 6 for timestamp columns,
          # so we need to ensure we match this when setting the default value.
          def current_timestamp_literal
            if ActiveRecord.version >= Gem::Version.new("7.0") && activerecord_adapter == "mysql2" && ActiveRecord::Base.connection.supports_datetime_with_precision?
              "CURRENT_TIMESTAMP(6)"
            else
              "CURRENT_TIMESTAMP"
            end
          end
        else # Sequel
          include ::Rails::Generators::Migration

          MIGRATION_DIR = "#{__dir__}/migration/sequel"

          def self.next_migration_number(dirname)
            next_migration_number = current_migration_number(dirname) + 1
            [Time.now.utc.strftime('%Y%m%d%H%M%S'), format('%.14d', next_migration_number)].max
          end

          def db_migrate_path
            "db/migrate"
          end

          def db
            db = ::Sequel::DATABASES.first if defined?(::Sequel)
            db or fail Rodauth::Rails::Error, "missing Sequel database connection"
          end
        end
      end
    end
  end
end
