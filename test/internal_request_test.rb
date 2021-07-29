require "test_helper"

class InternalRequestTest < UnitTest
  test "inheriting URL options from config.action_mailer" do
    RodauthApp.rodauth.create_account(login: "user@example.com", password: "secret")
    email = ActionMailer::Base.deliveries.last
    assert_match %r{https://example\.com}, email.body.to_s
  end

  test "allowing overriding URL options" do
    env = { "HTTP_HOST" => "foobar.com", "rack.url_scheme" => "http" }
    RodauthApp.rodauth.create_account(login: "user@example.com", password: "secret", env: env)
    email = ActionMailer::Base.deliveries.last
    assert_match %r{http://foobar\.com}, email.body.to_s
  end

  test "internal request eval" do
    path = RodauthApp.rodauth.internal_request_eval { login_path }
    assert_equal "/login", path
  end

  test "skipping callbacks" do
    env = { "QUERY_STRING" => "early_return=true" }
    RodauthApp.rodauth.create_account(login: "user@example.com", password: "secret", env: env)
    assert_equal 1, Account.count
  end

  test "skipping rescue handlers" do
    params = { "raise" => "true" }
    assert_raises NotImplementedError do
      RodauthApp.rodauth.create_account(login: "user@example.com", password: "secret", params: params)
    end
  end

  test "skipping instrumentation" do
    events = []
    ActiveSupport::Notifications.subscribe(/action_controller/) { |event| events << event }
    RodauthApp.rodauth.create_account(login: "user@example.com", password: "secret")
    assert_empty events
  end
end
