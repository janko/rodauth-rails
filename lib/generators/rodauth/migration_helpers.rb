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
            .select { |feature| File.exist?("#{__dir__}/migration/#{feature}.erb") }
            .map { |feature| File.read("#{__dir__}/migration/#{feature}.erb") }
            .map { |content| erb_eval(content) }
            .join("\n")
            .indent(4)
        end

        def activerecord_adapter
          if ActiveRecord::Base.respond_to?(:connection_db_config)
            ActiveRecord::Base.connection_db_config.adapter
          else
            ActiveRecord::Base.connection_config.fetch(:adapter)
          end
        end

        def migration_version
          return unless ActiveRecord.version >= Gem::Version.new("5.0")

          "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
        end

        def db_migrate_path
          return "db/migrate" unless ActiveRecord.version >= Gem::Version.new("5.0")

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
          if RUBY_VERSION >= "2.4"
            ERB.new(content, trim_mode: "-").result(binding)
          else
            ERB.new(content, 0, "-").result(binding)
          end
        end
      end
    end
  end
end
