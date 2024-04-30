ENV["RAILS_ENV"] = "test"

require "warning"
Warning.ignore(:ambiguous_slash, __dir__)
Gem.path.each { |path| Warning.ignore(//, path) } # ignore warnings in dependencies

require "bundler/setup"
require "i18n/backend"
require_relative "rails_app/config/environment"
require "rails/test_help"
require "capybara/rails"

puts "Rails #{Rails.version}" if ENV["CI"]

ActiveRecord::Migrator.migrations_paths = [Rails.root.join("db/migrate")]
Rails.backtrace_cleaner.remove_silencers! # show full stack traces

module TestSetupTeardown
  def setup
    super
    if ActiveRecord.version >= Gem::Version.new("7.2.0.alpha")
      ActiveRecord::Base.connection_pool.migration_context.up
    elsif ActiveRecord.version >= Gem::Version.new("5.2")
      ActiveRecord::Base.connection.migration_context.up
    else
      ActiveRecord::Migrator.up(Rails.application.paths["db/migrate"].to_a)
    end
  end

  def teardown
    super
    if ActiveRecord.version >= Gem::Version.new("7.2.0.alpha")
      ActiveRecord::Base.connection_pool.migration_context.up
    elsif ActiveRecord.version >= Gem::Version.new("5.2")
      ActiveRecord::Base.connection.migration_context.down
    else
      ActiveRecord::Migrator.down(Rails.application.paths["db/migrate"].to_a)
    end
    ActiveRecord::Base.clear_cache! # clear schema cache
    ActionMailer::Base.deliveries.clear
  end
end

class UnitTest < ActiveSupport::TestCase
  self.test_order = :random
  include TestSetupTeardown
end

class IntegrationTest < UnitTest
  include Capybara::DSL

  def register(login: "user@example.com", password: "secret", verify: false)
    visit "/create-account"
    fill_in "Login", with: login
    fill_in "Password", with: password
    fill_in "Confirm Password", with: password
    click_on "Create Account"

    if verify
      email = ActionMailer::Base.deliveries.last
      verify_account_link = email.body.to_s[%r{/verify-account\S+}]

      visit verify_account_link
      click_on "Verify Account"
    end
  end

  def login(login: "user@example.com", password: "secret")
    visit "/login"
    fill_in "Login", with: login
    fill_in "Password", with: password
    click_on "Login"
  end

  def logout
    visit "/logout"
    click_on "Logout"
  end

  def teardown
    super
    Capybara.reset_sessions!
  end
end
