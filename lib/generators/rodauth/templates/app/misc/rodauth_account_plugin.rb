require "sequel/core"

class Rodauth<%= table_prefix.classify %>Plugin < RodauthPlugin
  configure do
    # This block is running inside of
    #   plugin :rodauth do
    #     ...
    #   end

    # ==> Features
    # See the Rodauth documentation for the list of available config options:
    # http://rodauth.jeremyevans.net/documentation.html

    # List of authentication features that are loaded.
    enable <%= enabled_plugins.map(&:inspect).join ', ' %>

    # ==> General

    # Change prefix of table and foreign key column names from default "account"
    # accounts_table: '<%= table %>'

    # The secret key used for hashing public-facing tokens for various features.
    # Defaults to Rails `secret_key_base`, but you can use your own secret key.
    # hmac_secret "<SECRET_KEY>"

    # Use path prefix for all routes.
    <%= '# ' if primary? %>prefix "/<%= table_prefix.pluralize %>"

    # Specify the controller used for view rendering, CSRF, and callbacks.
    rails_controller { <%= "#{table_prefix.classify}::" unless primary? %>RodauthController }
<% if verify_account? -%>

    # Set password when creating account instead of when verifying.
    verify_account_set_password? false
<% end -%>

    # Change some default param keys.
    # login_param "email"
    # password_confirm_param "confirm_password"

    # Redirect back to originally requested location after authentication.
    # login_return_to_requested_location? true
    # two_factor_auth_return_to_requested_location? true # if using MFA

    # Autologin the user after they have reset their password.
    # reset_password_autologin? true

    # Delete the account record when the user has closed their account.
    # delete_account_on_close? true

    # Redirect to the app from login and registration pages if already logged in.
    # already_logged_in { redirect login_redirect }
<% if jwt? -%>

    # ==> JWT

    # Set JWT secret, which is used to cryptographically protect the token.
    jwt_secret Rails.application.credentials.secret_key_base
<% end -%>
<% if only_json? -%>

    # ==> Api only

    # Accept only JSON requests.
    only_json? true

    # Handle login and password confirmation fields on the client side.
    require_password_confirmation? false
    require_login_confirmation? false
<% else -%>

    # Accept both api and form requests
    # Requires the JSON feature
    <%= '# ' unless json? %>only_json? false
<% end -%>
<% if mails? -%>

    # ==> Emails
    # Use a custom mailer for delivering authentication emails.
<% if reset_password? -%>

    create_reset_password_email do
      Rodauth<%= table_prefix.classify %>Mailer.reset_password(self.class.configuration_name, account_id, reset_password_key_value)
    end
<% end -%>
<% if verify_account? -%>

    create_verify_account_email do
      Rodauth<%= table_prefix.classify %>Mailer.verify_account(self.class.configuration_name, account_id, verify_account_key_value)
    end
<% end -%>
<% if verify_login_change? -%>

    create_verify_login_change_email do |_login|
      Rodauth<%= table_prefix.classify %>Mailer.verify_login_change(self.class.configuration_name, account_id, verify_login_change_key_value)
    end
<% end -%>
<% if change_password_notify? -%>

    create_password_changed_email do
      Rodauth<%= table_prefix.classify %>Mailer.change_password_notify(self.class.configuration_name, account_id)
    end
<% end -%>
<% if reset_password_notify? -%>

    create_reset_password_notify_email do
      Rodauth<%= table_prefix.classify %>Mailer.reset_password_notify(self.class.configuration_name, account_id)
    end
<% end -%>
<% if email_auth? -%>

    create_email_auth_email do
      Rodauth<%= table_prefix.classify %>Mailer.email_auth(self.class.configuration_name, account_id, email_auth_key_value)
    end
<% end -%>
<% if unlock_account? -%>

    create_unlock_account_email do
      Rodauth<%= table_prefix.classify %>Mailer.unlock_account(self.class.configuration_name, account_id, unlock_account_key_value)
    end
<% end -%>

    send_email do |email|
      # queue email delivery on the mailer after the transaction commits
      db.after_commit { email.deliver_later }
    end
<% end -%>
<% unless only_json? -%>

    # ==> Flash
    # Does not work with only_json?

    # Match flash keys with ones already used in the Rails app.
    # flash_notice_key :success # default is :notice
    # flash_error_key :error # default is :alert

    # Override default flash messages.
    # create_account_notice_flash "Your account has been created. Please verify your account by visiting the confirmation link sent to your email address."
    # require_login_error_flash "Login is required for accessing this page"
    # login_notice_flash nil
<% end -%>

    # ==> Validation
    # Override default validation error messages.
    # no_matching_login_message "user with this email address doesn't exist"
    # already_an_account_with_this_login_message "user with this email address already exists"
    # password_too_short_message { "needs to have at least #{password_minimum_length} characters" }
    # login_does_not_meet_requirements_message { "invalid email#{", #{login_requirement_message}" if login_requirement_message}" }

    # ==> Passwords

    # Passwords shorter than 8 characters are considered weak according to OWASP.
    <%= '# ' unless login? %>password_minimum_length 8

    # Custom password complexity requirements (alternative to password_complexity feature).
    # password_meets_requirements? do |password|
    #   super(password) && password_complex_enough?(password)
    # end
    # auth_class_eval do
    #   def password_complex_enough?(password)
    #     return true if password.match?(/\d/) && password.match?(/[^a-zA-Z\d]/)
    #     set_password_requirement_error_message(:password_simple, "requires one number and one special character")
    #     false
    #   end
    # end
<% unless argon2? -%>

    # = bcrypt

    # bcrypt has a maximum input length of 72 bytes, truncating any extra bytes.
    password_maximum_bytes 72
<% else -%>

    # = argon2

    # Use a rotatable password pepper when hashing passwords with Argon2.
    argon2_secret "TODO: <SECRET_KEY>"

    # Since we're using argon2, prevent loading the bcrypt gem to save memory.
    require_bcrypt? false

    # Having a maximum password length set prevents long password DoS attacks.
    password_maximum_length 64
<% end -%>
<% if remember? -%>

    # ==> Remember Feature

    # Remember all logged in users.
    after_login { remember_login }

    # Or only remember users that have ticked a "Remember Me" checkbox on login.
    # after_login { remember_login if param_or_nil("remember") }

    # Extend user's remember period when remembered via a cookie
    extend_remember_deadline? true
<% end -%>

    # ==> Hooks

    # Validate custom fields in the create account form.
    # before_create_account do
    #   throw_error_status(422, "name", "must be present") if param("name").empty?
    # end

    # Perform additional actions after the account is created.
    # after_create_account do
    #   Profile.create!(account_id: account_id, name: param("name"))
    # end

    # Do additional cleanup after the account is closed.
    # after_close_account do
    #   Profile.find_by!(account_id: account_id).destroy
    # end
<% unless only_json? -%>

    # ==> Redirects

    # Redirect to home page after logout.
    logout_redirect "/"

    # Redirect to wherever login redirects to after account verification.
    verify_account_redirect { login_redirect }

    # Redirect to login page after password reset.
    reset_password_redirect { login_path }

    # Ensure requiring login follows login route changes.
    require_login_redirect { login_path }
<% end -%>

    # ==> Deadlines
    # Change default deadlines for some actions.
    # verify_account_grace_period 3.days.to_i
    # reset_password_deadline_interval Hash[hours: 6]
    # verify_login_change_deadline_interval Hash[days: 2]
<% unless only_json? -%>
    # remember_deadline_interval Hash[days: 30]
<% end -%>
  end
end
