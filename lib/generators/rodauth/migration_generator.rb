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

        class_option :name, optional: true, type: :string,
          desc: "Name of the generated migration file"

        def create_rodauth_migration
          return if features.empty?

          migration_template "db/migrate/create_rodauth.rb", File.join(db_migrate_path, "#{migration_name}.rb")
        end

        private

        def migration_name
          options[:name] || "create_rodauth_#{features.join("_")}"
        end

        def migration_content
          features
            .select { |feature| File.exist?(migration_chunk(feature)) }
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

        if defined?(::ActiveRecord::Railtie) # Active Record
          include ::ActiveRecord::Generators::Migration

          def db_migrate_path
            return "db/migrate" unless ActiveRecord.version >= Gem::Version.new("5.0")

            super
          end

          def migration_chunk(feature)
            "#{__dir__}/migration/active_record/#{feature}.erb"
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

            return unless column_type

            if key
              ", #{key}: :#{column_type}"
            else
              column_type
            end
          end

          def current_timestamp
            if ActiveRecord.version >= Gem::Version.new("5.0")
              %(-> { "CURRENT_TIMESTAMP" })
            else
              %(OpenStruct.new(quoted_id: "CURRENT_TIMESTAMP"))
            end
          end
        else # Sequel
          include ::Rails::Generators::Migration

          def self.next_migration_number(dirname)
            next_migration_number = current_migration_number(dirname) + 1
            [Time.now.utc.strftime('%Y%m%d%H%M%S'), format('%.14d', next_migration_number)].max
          end

          def db_migrate_path
            "db/migrate"
          end

          def migration_chunk(feature)
            "#{__dir__}/migration/sequel/#{feature}.erb"
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
