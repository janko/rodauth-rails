require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_job/railtie"
require "rails/test_unit/railtie"

require "rodauth-rails"

module RailsApp
  class Application < Rails::Application
    config.root = Pathname("#{__dir__}/..").expand_path
    config.logger = Logger.new(nil)
    config.eager_load = true
    config.action_dispatch.show_exceptions = false
    config.action_mailer.delivery_method = :test
    config.action_mailer.default_url_options = { host: "example.com", protocol: "https" }
    config.active_record.maintain_test_schema = false
    config.active_record.legacy_connection_handling = false if ActiveRecord::VERSION::MAJOR >= 7
  end
end
