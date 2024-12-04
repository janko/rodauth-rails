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
          return unless validate_features

          migration_template "db/migrate/create_rodauth.rb", File.join(db_migrate_path, "#{migration_name}.rb")
        end

        def show_configuration
          # skip if called from install generator, it already adds configuration
          return if current_command_chain.include?(:generate_rodauth_migration)
          return unless options[:prefix] && behavior == :invoke

          configuration = CONFIGURATION.values_at(*features.map(&:to_sym))
            .flat_map(&:to_a)
            .map { |config, format| "#{config} :#{format % { plural: table_prefix.pluralize, singular: table_prefix }}" }
            .join("\n")
            .indent(2)

          say "\nCopy the following lines into your Rodauth configuration:\n\n#{configuration}"
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
          ERB.new(content, trim_mode: "-").result(binding)
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

        CONFIGURATION = {
          base: { accounts_table: "%{plural}" },
          remember: { remember_table: "%{singular}_remember_keys" },
          verify_account: { verify_account_table: "%{singular}_verification_keys" },
          verify_login_change: { verify_login_change_table: "%{singular}_login_change_keys" },
          reset_password: { reset_password_table: "%{singular}_password_reset_keys" },
          email_auth: { email_auth_table: "%{singular}_email_auth_keys" },
          otp: { otp_keys_table: "%{singular}_otp_keys" },
          otp_unlock: { otp_unlock_table: "%{singular}_otp_unlocks" },
          sms_codes: { sms_codes_table: "%{singular}_sms_codes" },
          recovery_codes: { recovery_codes_table: "%{singular}_recovery_codes" },
          webauthn: { webauthn_keys_table: "%{singular}_webauthn_keys", webauthn_user_ids_table: "%{singular}_webauthn_user_ids", webauthn_keys_account_id_column: "%{singular}_id" },
          lockout: { account_login_failures_table: "%{singular}_login_failures", account_lockouts_table: "%{singular}_lockouts" },
          active_sessions: { active_sessions_table: "%{singular}_active_session_keys", active_sessions_account_id_column: "%{singular}_id" },
          account_expiration: { account_activity_table: "%{singular}_activity_times" },
          password_expiration: { password_expiration_table: "%{singular}_password_change_times" },
          single_session: { single_session_table: "%{singular}_session_keys" },
          audit_logging: { audit_logging_table: "%{singular}_authentication_audit_logs", audit_logging_account_id_column: "%{singular}_id" },
          disallow_password_reuse: { previous_password_hash_table: "%{singular}_previous_password_hashes", previous_password_account_id_column: "%{singular}_id" },
          jwt_refresh: { jwt_refresh_token_table: "%{singular}_jwt_refresh_keys", jwt_refresh_token_account_id_column: "%{singular}_id" },
        }

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
            generators  = ::Rails.configuration.generators
            column_type = generators.options[:active_record][:primary_key_type]

            if key
              ", #{key}: :#{column_type}" if column_type
            else
              column_type || default_primary_key_type
            end
          end

          def default_primary_key_type
            activerecord_adapter == "sqlite3" ? :integer : :bigint
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
