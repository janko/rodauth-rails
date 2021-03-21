require "test_helper"

class AppTest < UnitTest
  test "middleware inspect output" do
    app = -> (env) { [200, {}, []] }
    env = { "PATH_INFO" => "/" }
    RodauthApp.new(app).call(env)

    middleware = env["rodauth"].scope

    assert_equal "RodauthApp::Middleware", middleware.class.inspect
    assert_match /#<RodauthApp::Middleware request=.+ response=.+>/, middleware.inspect
  end
end
