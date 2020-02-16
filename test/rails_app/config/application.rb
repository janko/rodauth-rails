require_relative "boot"

require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"

# require "rodauth/rails"

module RailsApp
  class Application < Rails::Application
    config.root = Pathname("#{__dir__}/..").expand_path
    config.eager_load = false
  end
end
