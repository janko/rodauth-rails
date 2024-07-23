require "test_helper"
require "generators/rodauth/views_generator"

class ViewsGeneratorTest < Rails::Generators::TestCase
  tests Rodauth::Rails::Generators::ViewsGenerator
  destination File.expand_path("#{__dir__}/../../tmp")
  setup :prepare_destination

  test "default views" do
    run_generator

    templates = %w[
      _login_form _login_form_footer login multi_phase_login
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
    run_generator %w[lockout confirm_password]

    assert_file "app/views/rodauth/unlock_account_request.html.erb"
    assert_file "app/views/rodauth/unlock_account.html.erb"
    assert_file "app/views/rodauth/confirm_password.html.erb"

    assert_no_file "app/views/rodauth/login.html.erb"
    assert_no_file "app/views/rodauth/create_account.html.erb"
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

  test "specifying tailwind templates" do
    run_generator %w[--css=tailwind --all]

    assert_file "app/views/rodauth/_login_form.html.erb", /dark:focus:ring-emerald-400/
  end

  test "interpolating named configuration" do
    run_generator %w[verify_login_change]

    assert_file "app/views/rodauth/verify_login_change.html.erb", <<~ERB
      <%= form_with url: rodauth.verify_login_change_path, method: :post, data: { turbo: false } do |form| %>
        <div class="form-group mb-3">
          <%= form.submit rodauth.verify_login_change_button, class: "btn btn-primary" %>
        </div>
      <% end %>
    ERB

    run_generator %w[verify_login_change --name admin]

    assert_file "app/views/admin/rodauth/verify_login_change.html.erb", <<~ERB
      <%= form_with url: rodauth(:admin).verify_login_change_path, method: :post, data: { turbo: false } do |form| %>
        <div class="form-group mb-3">
          <%= form.submit rodauth(:admin).verify_login_change_button, class: "btn btn-primary" %>
        </div>
      <% end %>
    ERB
  end if ActionView.version >= Gem::Version.new("5.1")

  test "interpolating directory name" do
    run_generator %w[recovery_codes]

    assert_file "app/views/rodauth/add_recovery_codes.html.erb", <<~ERB
      <pre id="recovery-codes"><%= rodauth.recovery_codes.map { |s| h(s) }.join("\\n\\n") %></pre>

      <% if rodauth.can_add_recovery_codes? %>
        <%== rodauth.add_recovery_codes_heading %>
        <%= render template: "rodauth/recovery_codes", layout: false %>
      <% end %>
    ERB

    run_generator %w[recovery_codes --name admin]

    assert_file "app/views/admin/rodauth/add_recovery_codes.html.erb", <<~ERB
      <pre id="recovery-codes"><%= rodauth(:admin).recovery_codes.map { |s| h(s) }.join("\\n\\n") %></pre>

      <% if rodauth(:admin).can_add_recovery_codes? %>
        <%== rodauth(:admin).add_recovery_codes_heading %>
        <%= render template: "admin/rodauth/recovery_codes", layout: false %>
      <% end %>
    ERB
  end if ActionView.version >= Gem::Version.new("5.1")

  if ActionView.version < Gem::Version.new("5.1")
    test "form helpers compatibility" do
      run_generator %w[close_account remember logout]

      assert_file "app/views/rodauth/close_account.html.erb", <<~ERB
        <%= form_tag rodauth.close_account_path, method: :post, data: { turbo: false } do %>
          <% if rodauth.close_account_requires_password? %>
            <div class="form-group mb-3">
              <%= label_tag "password", rodauth.password_label, class: "form-label" %>
              <%= password_field_tag rodauth.password_param, "", id: "password", autocomplete: rodauth.password_field_autocomplete_value, required: true, class: "form-control \#{"is-invalid" if rodauth.field_error(rodauth.password_param)}", aria: ({ invalid: true, describedby: "password_error_message" } if rodauth.field_error(rodauth.password_param)) %>
              <%= content_tag(:span, rodauth.field_error(rodauth.password_param), class: "invalid-feedback", id: "password_error_message") if rodauth.field_error(rodauth.password_param) %>
            </div>
          <% end %>

          <div class="form-group mb-3">
            <%= submit_tag rodauth.close_account_button, class: "btn btn-danger" %>
          </div>
        <% end %>
      ERB

      assert_file "app/views/rodauth/remember.html.erb", <<~ERB
        <%= form_tag rodauth.remember_path, method: :post, data: { turbo: false } do %>
          <fieldset class="form-group mb-3">
            <div class="form-check">
              <%= radio_button_tag rodauth.remember_param, rodauth.remember_remember_param_value, false, id: "remember-remember", class: "form-check-input" %>
              <%= label_tag "remember-remember", rodauth.remember_remember_label, class: "form-check-label" %>
            </div>

            <div class="form-check">
              <%= radio_button_tag rodauth.remember_param, rodauth.remember_forget_param_value, false, id: "remember-forget", class: "form-check-input" %>
              <%= label_tag "remember-forget", rodauth.remember_forget_label, class: "form-check-label" %>
            </div>

            <div class="form-check">
              <%= radio_button_tag rodauth.remember_param, rodauth.remember_disable_param_value, false, id: "remember-disable", class: "form-check-input" %>
              <%= label_tag "remember-disable", rodauth.remember_disable_label, class: "form-check-label" %>
            </div>
          </fieldset>

          <div class="form-group mb-3">
            <%= submit_tag rodauth.remember_button, class: "btn btn-primary" %>
          </div>
        <% end %>
      ERB

      assert_file "app/views/rodauth/logout.html.erb", <<~ERB
        <%= form_tag rodauth.logout_path, method: :post, data: { turbo: false } do %>
          <% if rodauth.features.include?(:active_sessions) %>
            <div class="form-group mb-3">
              <div class="form-check">
                <%= check_box_tag rodauth.global_logout_param, "t", false, id: "global-logout", class: "form-check-input", include_hidden: false %>
                <%= label_tag "global-logout", rodauth.global_logout_label, class: "form-check-label" %>
              </div>
            </div>
          <% end %>

          <div class="form-group mb-3">
            <%= submit_tag rodauth.logout_button, class: "btn btn-warning" %>
          </div>
        <% end %>
      ERB
    end
  end

  test "specifying configuration with no controller" do
    assert_raises Rodauth::Rails::Error do
      run_generator %w[--name json]
    end
  end

  test "specifying unknown configuration" do
    assert_raises Rodauth::Rails::Error do
      run_generator %w[--name unknown]
    end
  end

  test "invalid features" do
    output = run_generator %w[otp active_sessions]

    assert_equal "No available view template for feature(s): active_sessions\n", output
    assert_no_file "app/views/rodauth/otp_auth.html.erb"
  end
end
