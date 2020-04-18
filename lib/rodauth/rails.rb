require "rails"
require "sequel/core"

require "rodauth/rails/railtie"
require "rodauth/rails/configuration"

module Rodauth
  module Rails
    class Error < StandardError; end

    autoload :App, "rodauth/rails/app"

    def self.sequel_connect
      return if Sequel::DATABASES.any?
      Sequel.connect config.db_options.merge(extensions: [:date_arithmetic])
    end

    def self.sequel_disconnect
      Sequel::DATABASES.first&.disconnect
      Sequel.synchronize { Sequel::DATABASES.pop }
    end

    def self.configure
      yield config
    end

    def self.config
      Configuration.instance
    end

    def self.auth_class(name = nil)
      config.app.rodauth(name)
    end
  end
end
