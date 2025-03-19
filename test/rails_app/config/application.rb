require "rails"
require "logger" if Rails.gem_version >= Gem::Version.new("6.0") && Rails.gem_version < Gem::Version.new("7.1")
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_cable/engine"
require "active_job/railtie"
require "rails/test_unit/railtie"

require "rodauth-rails"
begin
  require "turbo-rails"
rescue LoadError
end

module RailsApp
  class Application < Rails::Application
    config.root = Pathname("#{__dir__}/..").expand_path
    config.secret_key_base = "a8457c8003e83577e92708bd56e19bdc4442c689f458f483a30e580611c578a3"
    config.logger = Logger.new(nil)
    config.eager_load = true
    config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
    config.action_dispatch.show_exceptions = Rails.gem_version >= Gem::Version.new("7.1") ? :none : false
    config.action_mailer.delivery_method = :test
    config.action_mailer.default_url_options = { host: "example.com", protocol: "https" }
    config.active_record.maintain_test_schema = false
    config.active_record.legacy_connection_handling = false if ActiveRecord::VERSION::MAJOR == 7 && ActiveRecord::VERSION::MINOR == 0
  end
end
