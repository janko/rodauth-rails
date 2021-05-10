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

    templates.each do |template|
      assert_file "app/views/rodauth/#{template}.html.erb"
    end

    assert_no_file "app/views/rodauth/otp_auth.html.erb"
    assert_no_file "app/views/rodauth/_sms_code_field.html.erb"
  end

  test "choosing features" do
    run_generator ["lockout"]

    %w[_login_hidden_field _submit unlock_account_request unlock_account].each do |template|
      assert_file "app/views/rodauth/#{template}.html.erb"
    end

    assert_no_file "app/views/rodauth/create_account.html.erb"
    assert_no_file "app/views/rodauth/_login_confirm_field.html.erb"
  end

  test "dependencies" do
    run_generator ["sms_codes"]

    templates = %w[
      _field _field_error _password_field _submit two_factor_manage
      _sms_code_field _sms_phone_field two_factor_auth two_factor_disable
      sms_setup sms_confirm sms_auth sms_request sms_disable
    ]

    templates.each do |template|
      assert_file "app/views/rodauth/#{template}.html.erb"
    end
  end

  test "all features" do
    run_generator ["--all"]

    assert_file "app/views/rodauth/login.html.erb"
    assert_file "app/views/rodauth/otp_auth.html.erb"
    assert_file "app/views/rodauth/webauthn_setup.html.erb"
  end

  test "specifying directory" do
    run_generator %w[--directory authentication]

    assert_file "app/views/authentication/login.html.erb"
    assert_no_directory "app/views/rodauth"
  end

  test "login_form_footer template" do
    run_generator

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
  end

  test "logout template" do
    run_generator

    assert_file "app/views/rodauth/logout.html.erb", <<-ERB.strip_heredoc
      <%= form_tag rodauth.logout_path, method: :post do %>
        <%= render "global_logout_field" if rodauth.features.include?(:active_sessions) %>
        <%= render "submit", value: "Logout", class: "btn btn-warning" %>
      <% end %>
    ERB
  end

  test "otp_auth template" do
    run_generator %w[otp]

    assert_file "app/views/rodauth/otp_auth.html.erb", <<-ERB.strip_heredoc
      <%= form_tag rodauth.otp_auth_path, method: :post do %>
        <%= render "otp_auth_code_field" %>
        <%= render "submit", value: "Authenticate Using TOTP" %>
      <% end %>
    ERB
  end

  test "password_field partial" do
    run_generator %w[create_account]

    assert_file "app/views/rodauth/_password_field.html.erb", <<-ERB.strip_heredoc
      <div class="form-group mb-3">
        <%= label_tag "password", "Password", class: "form-label" %>
        <%= render "field", name: rodauth.password_param, id: "password", type: :password, value: "", autocomplete: rodauth.password_field_autocomplete_value %>
      </div>
    ERB
  end

  test "deprecated --features option" do
    run_generator %w[--features lockout]

    %w[_login_hidden_field _submit unlock_account_request unlock_account].each do |template|
      assert_file "app/views/rodauth/#{template}.html.erb"
    end
  end
end
