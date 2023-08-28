require "rails/generators/base"
require "rails/generators/active_record/migration"
require "erb"

require "#{__dir__}/concerns/configuration"
require "#{__dir__}/concerns/accepts_table"

module Rodauth
  module Rails
    module Generators
      class MigrationGenerator < ::Rails::Generators::Base
        include Concerns::Configuration
        include Concerns::AcceptsTable

        source_root "#{__dir__}/templates"
        namespace "rodauth:migration"

        desc "Generate migrations for specific features.\n\n" \
             "Available features:\n" \
             "=========================================\n" \
             "#{CONFIGURATION.select{ |k, v| v[:migrations] != false }.keys.sort.map(&:to_s).join "\n"}"

        class_option :features, optional: true, type: :array,
          desc: "Rodauth features to create tables for (otp, sms_codes, single_session, account_expiration etc.)",
          default: %w[]

        def create_rodauth_migration
          validate_features

          migration_template "db/migrate/create_rodauth.rb", File.join(db_migrate_path, "#{migration_name}.rb")
        end

        def configure_rodauth_account
          if features.include? 'create_account'
            gsub_file "app/misc/rodauth_#{table_prefix}_plugin.rb", /.*# accounts_table.*\n/, ''
          end

          migration_overrides.reverse_each do |key, value|
            override = indent "#{key} :#{value}\n", 4
            insert_into_file "app/misc/rodauth_#{table_prefix}_plugin.rb", override,
              after: /.*# Change prefix of table and.*\n/
          end
        end

        private

        def migration_name
          options[:migration_name] || ["create_rodauth", table_prefix, *features].join("_")
        end

        def features
          @features ||= begin
            selected_features = options[:features]
            selected_features.unshift 'create_account' if selected_features.delete 'create_account'
            selected_features
          end
        end

        def migration_overrides
          @migration_overrides ||= self.class::CONFIGURATION.values_at(*features.map(&:to_sym))
            .flat_map(&:to_a)
            .filter { |config, format| config.ends_with? "_table"  }
            .map { |config, format| [config, (format % { plural: table_prefix.pluralize, singular: table_prefix })] }
            .to_h
            .compact
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
            exit(1)
          elsif (features - valid_features).any?
            say "No available migration for feature(s): #{(features - valid_features).join(", ")}", :red
            exit(1)
          end
        end

        def valid_features
          Dir["#{MIGRATION_DIR}/*.erb"].map { |filename| File.basename(filename, ".erb") }
        end

        if defined?(::ActiveRecord::Railtie) # Active Record
          include ::ActiveRecord::Generators::Migration

          MIGRATION_DIR = "#{__dir__}/migration/active_record"

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

          # Active Record 7+ sets default precision to 6 for timestamp columns,
          # so we need to ensure we match this when setting the default value.
          def current_timestamp
            if ActiveRecord.version >= Gem::Version.new("7.0") && ["mysql2", "trilogy"].include?(activerecord_adapter) && ActiveRecord::Base.connection.supports_datetime_with_precision?
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
