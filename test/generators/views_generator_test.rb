require "test_helper"
require "generators/rodauth/views_generator"

class ViewsGeneratorTest < Rails::Generators::TestCase
  tests Rodauth::Rails::Generators::ViewsGenerator
  destination File.expand_path("#{__dir__}/../../tmp")
  setup :prepare_destination

  test "default views" do
    run_generator

    templates = %w[
      _field _field_error _login_field _login_display _password_field _submit
      _login_form _login_form_footer _login_form_header login multi_phase_login
      logout _login_confirm_field _password_confirm_field create_account
      _login_hidden_field reset_password_request reset_password change_login
      change_password _new_password_field close_account
    ]

    if Rodauth::MAJOR == 1
      templates -= %w[multi_phase_login]
    end

    templates.each do |template|
      assert_file "app/views/rodauth/#{template}.html.erb"
    end

    assert_no_file "app/views/rodauth/otp_auth.html.erb"
    assert_no_file "app/views/rodauth/_sms_code_field.html.erb"
  end

  test "choosing features" do
    run_generator ["--features", "lockout"]

    %w[_login_hidden_field _submit unlock_account_request unlock_account].each do |template|
      assert_file "app/views/rodauth/#{template}.html.erb"
    end

    assert_no_file "app/views/rodauth/create_account.html.erb"
    assert_no_file "app/views/rodauth/_login_confirm_field.html.erb"
  end

  test "dependencies" do
    run_generator ["--features", "sms_codes"]

    templates = %w[
      _field _field_error _password_field _submit two_factor_manage
      _sms_code_field _sms_phone_field two_factor_auth two_factor_disable
      sms_setup sms_confirm sms_auth sms_request sms_disable
    ]

    if Rodauth::MAJOR == 1
      templates -= %w[two_factor_auth two_factor_disable two_factor_manage]
    end

    templates.each do |template|
      assert_file "app/views/rodauth/#{template}.html.erb"
    end
  end

  test "all features" do
    run_generator ["--all"]

    assert_file "app/views/rodauth/login.html.erb"
    assert_file "app/views/rodauth/otp_auth.html.erb"
    assert_file "app/views/rodauth/webauthn_setup.html.erb" if Rodauth::MAJOR == 2
  end

  test "specifying directory" do
    run_generator %w[--directory authentication]

    assert_file "app/views/authentication/login.html.erb"
    assert_no_directory "app/views/rodauth"
  end

  test "login_form_footer template" do
    run_generator

    if Rodauth::MAJOR == 2
      assert_file "app/views/rodauth/_login_form_footer.html.erb", <<-ERB.strip_heredoc
        <% unless rodauth.login_form_footer_links.empty? %>
          <h2>Other Options</h2>
          <ul>
            <% rodauth.login_form_footer_links.sort.each do |_, link, text| %>
              <li><%= link_to text, link %></li>
            <% end %>
          </ul>
        <% end %>
      ERB
    else
      assert_file "app/views/rodauth/_login_form_footer.html.erb", <<-ERB.strip_heredoc
        <% if rodauth.features.include?(:create_account) %>
          <p><%= link_to "Create a New Account", rodauth.create_account_path %></p>
        <% end %>
        <% if rodauth.features.include?(:reset_password) %>
          <p><%= link_to "Forgot Password?", rodauth.reset_password_request_path %></p>
        <% end %>
        <% if rodauth.features.include?(:email_auth) && rodauth.valid_login_entered? %>
          <%= render "email_auth_request_form" %>
        <% end %>
        <% if rodauth.features.include?(:verify_account) %>
          <p><%= link_to "Resend Verify Account Information", rodauth.verify_account_resend_path %></p>
        <% end %>
      ERB
    end
  end

  test "logout template" do
    run_generator

    if Rodauth::MAJOR >= 2
      assert_file "app/views/rodauth/logout.html.erb", <<-ERB.strip_heredoc
        <%= form_tag rodauth.logout_path, method: :post do %>
          <%= render "global_logout_field" if rodauth.features.include?(:active_sessions) %>
          <%= render "submit", value: "Logout", class: "btn btn-warning" %>
        <% end %>
      ERB
    else
      assert_file "app/views/rodauth/logout.html.erb", <<-ERB.strip_heredoc
        <%= form_tag rodauth.logout_path, method: :post do %>
          <%= render "submit", value: "Logout", class: "btn btn-warning" %>
        <% end %>
      ERB
    end
  end

  test "otp_auth template" do
    run_generator %w[--features otp]

    if Rodauth::MAJOR >= 2
      assert_file "app/views/rodauth/otp_auth.html.erb", <<-ERB.strip_heredoc
        <%= form_tag rodauth.otp_auth_path, method: :post do %>
          <%= render "otp_auth_code_field" %>
          <%= render "submit", value: "Authenticate Using TOTP" %>
        <% end %>
      ERB
    else
      assert_file "app/views/rodauth/otp_auth.html.erb", <<-ERB.strip_heredoc
        <%= form_tag rodauth.otp_auth_path, method: :post do %>
          <%= render "otp_auth_code_field" %>
          <%= render "submit", value: "Authenticate Using TOTP" %>
        <% end %>

        <% if rodauth.features.include?(:sms_codes) && rodauth.sms_available? %>
          <p><%= link_to "Authenticate using SMS code", rodauth.sms_request_path %></p>
        <% end %>
        <% if rodauth.features.include?(:recovery_codes) %>
          <p><%= link_to "Authenticate using recovery code", rodauth.recovery_auth_path %></p>
        <% end %>
      ERB
    end
  end
end
