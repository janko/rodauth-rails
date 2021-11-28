require "erb"

module Rodauth
  module Rails
    module Generators
      module MigrationHelpers
        attr_reader :migration_class_name

        def migration_template(source, destination = File.basename(source))
          @migration_class_name = destination.chomp(".rb").camelize

          super source, File.join(db_migrate_path, destination)
        end

        private

        def migration_content
          migration_features
            .select { |feature| File.exist?(migration_chunk(feature)) }
            .map { |feature| File.read(migration_chunk(feature)) }
            .map { |content| erb_eval(content) }
            .join("\n")
            .indent(4)
        end

        def migration_chunk(feature)
          if defined?(ActiveRecord::Railtie)
            "#{__dir__}/migration/active_record/#{feature}.erb"
          elsif defined?(Sequel)
            "#{__dir__}/migration/sequel/#{feature}.erb"
          else
            fail Rodauth::Rails::Error, "unsupported database library (must be Active Record or Sequel)"
          end
        end

        def activerecord_adapter
          if ActiveRecord::Base.respond_to?(:connection_db_config)
            ActiveRecord::Base.connection_db_config.adapter
          else
            ActiveRecord::Base.connection_config.fetch(:adapter)
          end
        end

        def db
          Sequel::DATABASES.first or fail Rodauth::Rails::Error, "missing Sequel database connection"
        end

        def migration_version
          return unless ActiveRecord.version >= Gem::Version.new("5.0")

          "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
        end

        def db_migrate_path
          if defined?(ActiveRecord::Railtie) && ActiveRecord.version < Gem::Version.new("5.0") || defined?(Sequel)
            return "db/migrate"
          else
            super
          end

          super
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

        def erb_eval(content)
          if ERB.version[/\d+\.\d+\.\d+/].to_s >= "2.2.0"
            ERB.new(content, trim_mode: "-").result(binding)
          else
            ERB.new(content, 0, "-").result(binding)
          end
        end
      end
    end
  end
end
