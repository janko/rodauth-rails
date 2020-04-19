require "rails"
require "sequel/core"
require "dry/configurable"

require "rodauth/rails/railtie"

module Rodauth
  module Rails
    # This allows the developer to avoid loading Rodauth at boot time.
    autoload :App, "rodauth/rails/app"

    extend Dry::Configurable

    setting :app
    setting :sequel_config
    setting :activerecord_config
    setting :activerecord_extension, true
    setting :middleware, true
    setting :sequel_autoconnect, true

    class << self
      def auth_class(name = nil)
        app.rodauth(name)
      end

      def app
        fail Rodauth::Rails::Error, "app was not configured" unless config.app

        config.app.constantize
      end

      def sequel_connect
        return unless Sequel::DATABASES.empty?

        db = Sequel.connect config.sequel_config || activerecord_sequel_config
        db.extension :date_arithmetic # used by Rodauth
        db
      end

      def sequel_disconnect
        return if Sequel::DATABASES.empty?

        db = Sequel::DATABASES.last
        db.disconnect

        Sequel.synchronize { Sequel::DATABASES.delete(db) }
      end

      # Converts ActiveRecord database options into Sequel database options.
      def activerecord_sequel_config(config = nil)
        config ||= self.config.activerecord_config
        config ||= ActiveRecord::Base.configurations[::Rails.env]

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

    class Error < StandardError
    end
  end
end
