ENV["RAILS_ENV"] = "test"

require "warning"
Warning.ignore(:ambiguous_slash, __dir__)

require "bundler/setup"
require "i18n/backend"
require "i18n/backend/simple" # workaround for https://github.com/jruby/jruby/issues/6547
require_relative "rails_app/config/environment"
require "rails/test_help"
require "capybara/rails"

ActiveRecord::Migrator.migrations_paths = [Rails.root.join("db/migrate")]
Rails.backtrace_cleaner.remove_silencers! # show full stack traces

module TestSetupTeardown
  def setup
    super
    if ActiveRecord.version >= Gem::Version.new("5.2")
      ActiveRecord::Base.connection.migration_context.up
    else
      ActiveRecord::Migrator.up(Rails.application.paths["db/migrate"].to_a)
    end
  end

  def teardown
    super
    if ActiveRecord.version >= Gem::Version.new("5.2")
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

# a workaround to avoid MonitorMixin double-initialize error
# https://github.com/rails/rails/issues/34790#issuecomment-681034561
if RUBY_VERSION >= "2.6" && ActionPack.version < Gem::Version.new("5.0")
  class ActionController::TestResponse < ActionDispatch::TestResponse
    def recycle!
      if RUBY_VERSION >= "2.7" || RUBY_ENGINE == "jruby"
        @mon_data = nil
        @mon_data_owner_object_id = nil
      else
        @mon_mutex = nil
        @mon_mutex_owner_object_id = nil
      end
      initialize
    end
  end
end
