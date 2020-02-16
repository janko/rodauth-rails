ENV["RAILS_ENV"] = "test"

require_relative "rails_app/config/environment"

ActiveRecord::Tasks::DatabaseTasks.migrate

require "rails/test_help"
