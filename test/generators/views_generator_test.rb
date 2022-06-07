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

  test "specifying css tailwind" do
    run_generator %w[--css=tailwind]

    assert_file "app/views/rodauth/login.html.erb"
    assert_file "app/views/rodauth/logout.html.erb"
		assert_no_file "app/views/admin/rodauth/logout.html.erb"
  end

	test "that the tailwind file is being copied, rather than the bootstrap file" do
		run_generator %w[--css=tailwind logout]

	  assert_file "app/views/rodauth/logout.html.erb", <<~ERB.strip()
<% content_for :title, rodauth.logout_page_title %>
<div class="flex justify-center">
  <%= form_with url: rodauth.logout_path, method: :post, data: { turbo: false } do |form| %>
    <% if rodauth.features.include?(:active_sessions) %>
      <div class="py-3">
        <%= form.check_box rodauth.global_logout_param, id: "global-logout", class: "appearance-none checked:bg-blue-500" %>
        <%= form.label "global-logout", rodauth.global_logout_label, class: "inline-block text-gray-800" %>
      </div>
    <% end %>
    <div class="py-3">
      <%= form.submit rodauth.logout_button, class: "px-8 py-2 font-semibold rounded-md flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-emerald-400 dark:text-gray-900" %>
    </div>
  </div>
<% end %>
		ERB
	

  end if ActionView.version >= Gem::Version.new("5.1")

  test "interpolating named configuration" do
    run_generator %w[verify_login_change]

    assert_file "app/views/rodauth/verify_login_change.html.erb", <<-ERB.strip_heredoc
      <% content_for :title, rodauth.verify_login_change_page_title %>

      <%= form_with url: rodauth.verify_login_change_path, method: :post, data: { turbo: false } do |form| %>
        <div class="form-group mb-3">
          <%= form.submit rodauth.verify_login_change_button, class: "btn btn-primary" %>
        </div>
      <% end %>
    ERB

    run_generator %w[verify_login_change --name admin]

    assert_file "app/views/admin/rodauth/verify_login_change.html.erb", <<-ERB.strip_heredoc
      <% content_for :title, rodauth(:admin).verify_login_change_page_title %>

      <%= form_with url: rodauth(:admin).verify_login_change_path, method: :post, data: { turbo: false } do |form| %>
        <div class="form-group mb-3">
          <%= form.submit rodauth(:admin).verify_login_change_button, class: "btn btn-primary" %>
        </div>
      <% end %>
    ERB
  end if ActionView.version >= Gem::Version.new("5.1")

  test "interpolating directory name" do
    run_generator %w[login]

    assert_file "app/views/rodauth/_login_form_header.html.erb", <<-ERB.strip_heredoc
      <% if rodauth.field_error(rodauth.password_param) && rodauth.features.include?(:reset_password) %>
        <%= render template: "rodauth/reset_password_request", layout: false %>
      <% end %>
    ERB

    run_generator %w[login --name admin]

    assert_file "app/views/admin/rodauth/_login_form_header.html.erb", <<-ERB.strip_heredoc
      <% if rodauth(:admin).field_error(rodauth(:admin).password_param) && rodauth(:admin).features.include?(:reset_password) %>
        <%= render template: "admin/rodauth/reset_password_request", layout: false %>
      <% end %>
    ERB
  end if ActionView.version >= Gem::Version.new("5.1")

  if ActionView.version < Gem::Version.new("5.1")
    test "form helpers compatibility" do
      run_generator %w[close_account remember logout]

      assert_file "app/views/rodauth/close_account.html.erb", <<-ERB.strip_heredoc
        <% content_for :title, rodauth.close_account_page_title %>

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

      assert_file "app/views/rodauth/remember.html.erb", <<-ERB.strip_heredoc
        <% content_for :title, rodauth.remember_page_title %>

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

      assert_file "app/views/rodauth/logout.html.erb", <<-ERB.strip_heredoc
        <% content_for :title, rodauth.logout_page_title %>

        <%= form_tag rodauth.logout_path, method: :post, data: { turbo: false } do %>
          <% if rodauth.features.include?(:active_sessions) %>
            <div class="form-group mb-3">
              <div class="form-check">
                <%= check_box_tag rodauth.global_logout_param, "t", false, id: "global-logout", class: "form-check-input" %>
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
    assert_raises ArgumentError do
      run_generator %w[--name unknown]
    end
  end
end
