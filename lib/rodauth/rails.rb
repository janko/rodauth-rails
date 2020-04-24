require "rails"
require "dry/configurable"

require "rodauth/rails/railtie"

module Rodauth
  module Rails
    # This allows the developer to avoid loading Rodauth at boot time.
    autoload :App, "rodauth/rails/app"
    autoload :ActiveRecordIntegration, "rodauth/rails/active_record_integration"

    extend Dry::Configurable

    setting :app
    setting :middleware, true

    def self.app
      fail Rodauth::Rails::Error, "app was not configured" unless config.app

      config.app.constantize
    end

    def self.activerecord_integrate
      ActiveRecordIntegration.run
    end

    class Error < StandardError
    end
  end
end
