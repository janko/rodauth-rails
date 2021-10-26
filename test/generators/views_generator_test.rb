require "test_helper"
require "generators/rodauth/views_generator"

class ViewsGeneratorTest < Rails::Generators::TestCase
  tests Rodauth::Rails::Generators::ViewsGenerator
  destination File.expand_path("#{__dir__}/../../tmp")
  setup :prepare_destination

  test "default views" do
    run_generator

    templates = %w[
      _login_form _login_form_footer _login_form_header login multi_phase_login
      logout create_account reset_password_request verify_account
      reset_password change_login verify_login_change change_password
      close_account
    ]

    templates.each do |template|
      assert_file "app/views/rodauth/#{template}.html.erb"
    end

    assert_no_file "app/views/rodauth/otp_auth.html.erb"
  end

  test "choosing features" do
    run_generator %w[lockout]

    assert_file "app/views/rodauth/unlock_account_request.html.erb"
    assert_file "app/views/rodauth/unlock_account.html.erb"

    assert_no_file "app/views/rodauth/login.html.erb"
    assert_no_file "app/views/rodauth/create_account.html.erb"
  end

  test "dependencies" do
    run_generator %w[sms_codes]

    templates = %w[
      two_factor_manage two_factor_auth two_factor_disable
      sms_setup sms_confirm sms_auth sms_request sms_disable
    ]

    templates.each do |template|
      assert_file "app/views/rodauth/#{template}.html.erb"
    end
  end

  test "all features" do
    run_generator %w[--all]

    assert_file "app/views/rodauth/login.html.erb"
    assert_file "app/views/rodauth/otp_auth.html.erb"
    assert_file "app/views/rodauth/webauthn_setup.html.erb"
  end

  test "specifying configuration" do
    run_generator %w[--name admin]

    assert_file "app/views/admin/rodauth/login.html.erb"
    assert_no_file "app/views/admin/rodauth/logout.html.erb"
    assert_no_directory "app/views/rodauth"
  end

  test "ERB evaluation" do
    run_generator %w[verify_login_change]

    assert_file "app/views/rodauth/verify_login_change.html.erb", <<-ERB.strip_heredoc
      <%= form_tag rodauth.verify_login_change_path, method: :post do %>
        <div class="form-group mb-3">
          <%= submit_tag rodauth.verify_login_change_button, class: "btn btn-primary" %>
        </div>
      <% end %>
    ERB

    run_generator %w[verify_login_change --name admin]

    assert_file "app/views/admin/rodauth/verify_login_change.html.erb", <<-ERB.strip_heredoc
      <%= form_tag rodauth(:admin).verify_login_change_path, method: :post do %>
        <div class="form-group mb-3">
          <%= submit_tag rodauth(:admin).verify_login_change_button, class: "btn btn-primary" %>
        </div>
      <% end %>
    ERB
  end

  test "specifying configuration with no controller" do
    assert_raises Rodauth::Rails::Error do
      run_generator %w[--name json]
    end
  end

  test "specifying unknown configuration" do
    assert_raises ArgumentError do
      run_generator %w[--name unknown]
    end
  end
end
