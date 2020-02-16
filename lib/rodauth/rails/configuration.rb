require "singleton"

module Rodauth
  module Rails
    class Configuration
      include Singleton

      def app
        fail Rodauth::Rails::Error, "app was not configured" unless defined?(@app)

        Object.const_get(@app)
      end
      attr_writer :app

      def db_options
        @db_options ||= activerecord_db_options
      end
      attr_writer :db_options

      def db_adapter
        db_options.fetch(:adapter).to_sym
      end

      private

      def activerecord_db_options
        config = ActiveRecord::Base.configurations[::Rails.env]

        {
          adapter:         config.fetch("adapter").sub("sqlite3", "sqlite"),
          database:        config.fetch("database"),
          host:            config["host"],
          port:            config["port"],
          user:            config["username"],
          password:        config["password"],
          max_connections: config["pool"],
          pool_timeout:    config["checkout_timeout"],
        }.compact
      end
    end
  end
end
