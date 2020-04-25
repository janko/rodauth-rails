require "sequel/core"

module Rodauth
  module Rails
    module ActiveRecordIntegration
      # If there are no Sequel connections, creates a new "connection" that
      # just retrieves ActiveRecord's connection.
      def self.run
        return unless Sequel::DATABASES.empty?

        adapter = ActiveRecord::Base.connection_config.fetch(:adapter)
        adapter = adapter.sub("sqlite3", "sqlite")

        db = Sequel.connect(adapter: adapter, pool_class: ConnectionPool, test: false)
        db.extend(DatabaseMethods)
        db
      end

      # Connection pool that retrieves ActiveRecord connection instead of
      # letting Sequel create its own.
      class ConnectionPool < ::Sequel::ConnectionPool
        def hold(*)
          yield ConnectionWrapper.new(ActiveRecord::Base.connection)
        end
      end

      # Wrapper class with API Sequel expects from a connection object.
      class ConnectionWrapper
        def initialize(connection)
          @connection = connection
        end

        def execute(*args, &block)
          case @connection.adapter_name.downcase
          when "postgresql"
            activerecord_postgres_execute(*args, &block)
          else
            @connection.raw_connection.execute(*args, &block)
          end
        end

        private

        def activerecord_postgres_execute(*args)
          begin
            result = @connection.execute(*args)
          rescue ActiveRecord::RecordNotUnique => exception
            raise Sequel::UniqueConstraintViolation, exception.message, exception.backtrace
          end

          begin
            block_given? ? yield(result) : result.cmd_tuples
          ensure
            result.clear if result && result.respond_to?(:clear)
          end
        end

        def method_missing(name, *args, &block)
          @connection.raw_connection.send(name, *args, &block)
        end

        def respond_to_missing?(name, include_all)
          @connection.raw_connection.respond_to?(name, include_all)
        end
      end

      module DatabaseMethods
        def transaction(savepoint: nil, **)
          requires_new = savepoint == :only && ActiveRecord::Base.connection.transaction_open?

          ActiveRecord::Base.connection.transaction(requires_new: requires_new) do
            begin
              yield ConnectionWrapper.new(ActiveRecord::Base.connection)
            rescue Sequel::Rollback
              raise ActiveRecord::Rollback
            end
          end
        end
      end
    end
  end
end
