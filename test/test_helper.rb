ENV["RAILS_ENV"] = "test"

require "bundler/setup"
require "rodauth/version"
require_relative "rails_app/config/environment"
require "rails/test_help"

ActiveRecord::Migrator.migrations_paths = [Rails.root.join("db/migrate")]

Rails.backtrace_cleaner.remove_silencers! # show full stack traces

class IntegrationTest < ActionDispatch::SystemTestCase
  driven_by :rack_test

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

  def setup
    super
    ActiveRecord::Base.connection.migration_context.up
  end

  def teardown
    super
    ActiveRecord::Base.connection.migration_context.down
    ActionMailer::Base.deliveries.clear
  end
end
