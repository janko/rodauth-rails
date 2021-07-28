class RodauthApp < Rodauth::Rails::App
  configure do
    # List of authentication features that are loaded.
    enable :create_account, :verify_account, :verify_account_grace_period,
      :login, :logout<%= ", :remember" unless jwt? %><%= ", :json" if json? %><%= ", :jwt" if jwt? %>,
      :reset_password, :change_password, :change_password_notify,
      :change_login, :verify_login_change,
      :close_account

    # See the Rodauth documentation for the list of available config options:
    # http://rodauth.jeremyevans.net/documentation.html

    # ==> General
    # The secret key used for hashing public-facing tokens for various features.
    # Defaults to Rails `secret_key_base`, but you can use your own secret key.
    # hmac_secret "<%= SecureRandom.hex(64) %>"
<% if jwt? -%>

    # Set JWT secret, which is used to cryptographically protect the token.
    jwt_secret "<%= SecureRandom.hex(64) %>"
<% end -%>
<% if json? || jwt? -%>

    # Accept only JSON requests.
    only_json? true

    # Handle login and password confirmation fields on the client side.
    # require_password_confirmation? false
    # require_login_confirmation? false
<% end -%>

    # Specify the controller used for view rendering and CSRF verification.
    rails_controller { RodauthController }

    # Store account status in a text column.
    account_status_column :status
    account_unverified_status_value "unverified"
    account_open_status_value "verified"
    account_closed_status_value "closed"

    # Store password hash in a column instead of a separate table.
    # account_password_hash_column :password_digest

    # Set password when creating account instead of when verifying.
    verify_account_set_password? false

    # Redirect back to originally requested location after authentication.
    # login_return_to_requested_location? true
    # two_factor_auth_return_to_requested_location? true # if using MFA

    # Autologin the user after they have reset their password.
    # reset_password_autologin? true

    # Delete the account record when the user has closed their account.
    # delete_account_on_close? true

    # Redirect to the app from login and registration pages if already logged in.
    # already_logged_in { redirect login_redirect }

    # ==> Emails
    # Use a custom mailer for delivering authentication emails.
    create_reset_password_email do
      RodauthMailer.reset_password(email_to, reset_password_email_link)
    end
    create_verify_account_email do
      RodauthMailer.verify_account(email_to, verify_account_email_link)
    end
    create_verify_login_change_email do |login|
      RodauthMailer.verify_login_change(login, verify_login_change_old_login, verify_login_change_new_login, verify_login_change_email_link)
    end
    create_password_changed_email do
      RodauthMailer.password_changed(email_to)
    end
    # create_email_auth_email do
    #   RodauthMailer.email_auth(email_to, email_auth_email_link)
    # end
    # create_unlock_account_email do
    #   RodauthMailer.unlock_account(email_to, unlock_account_email_link)
    # end
    send_email do |email|
      # queue email delivery on the mailer after the transaction commits
      db.after_commit { email.deliver_later }
    end

    # ==> Flash
<% unless json? || jwt? -%>
    # Match flash keys with ones already used in the Rails app.
    # flash_notice_key :success # default is :notice
    # flash_error_key :error # default is :alert

<% end -%>
    # Override default flash messages.
    # create_account_notice_flash "Your account has been created. Please verify your account by visiting the confirmation link sent to your email address."
    # require_login_error_flash "Login is required for accessing this page"
    # login_notice_flash nil

    # ==> Validation
    # Override default validation error messages.
    # no_matching_login_message "user with this email address doesn't exist"
    # already_an_account_with_this_login_message "user with this email address already exists"
    # password_too_short_message { "needs to have at least #{password_minimum_length} characters" }
    # login_does_not_meet_requirements_message { "invalid email#{", #{login_requirement_message}" if login_requirement_message}" }

    # Change minimum number of password characters required when creating an account.
    # password_minimum_length 8
<% unless jwt? -%>

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
<% unless json? || jwt? -%>

    # ==> Redirects
    # Redirect to home page after logout.
    logout_redirect "/"

    # Redirect to wherever login redirects to after account verification.
    verify_account_redirect { login_redirect }

    # Redirect to login page after password reset.
    reset_password_redirect { login_path }
<% end -%>

    # ==> Deadlines
    # Change default deadlines for some actions.
    # verify_account_grace_period 3.days
    # reset_password_deadline_interval Hash[hours: 6]
    # verify_login_change_deadline_interval Hash[days: 2]
<% unless jwt? -%>
    # remember_deadline_interval Hash[days: 30]
<% end -%>
  end

  # ==> Secondary configurations
  # configure(:admin) do
  #   # ... enable features ...
  #   prefix "/admin"
  #   session_key_prefix "admin_"
  #   # remember_cookie_key "_admin_remember" # if using remember feature
  #
  #   # search views in `app/views/admin/rodauth` directory
  #   rails_controller { Admin::RodauthController }
  # end

  route do |r|
<% unless jwt? -%>
    rodauth.load_memory # autologin remembered users

<% end -%>
    r.rodauth # route rodauth requests

    # ==> Authenticating Requests
    # Call `rodauth.require_authentication` for requests that you want to
    # require authentication for. Some examples:
    #
    # next if r.path.start_with?("/docs") # skip authentication for documentation pages
    # next if session[:admin] # skip authentication for admins
    #
    # # authenticate /dashboard/* and /account/* requests
    # if r.path.start_with?("/dashboard") || r.path.start_with?("/account")
    #   rodauth.require_authentication
    # end

    # ==> Secondary configurations
    # r.on "admin" do
    #   r.rodauth(:admin)
    #
    #   unless rodauth(:admin).logged_in?
    #     rodauth(:admin).require_http_basic_auth
    #   end
    #
    #   break # allow the Rails app to handle other "/admin/*" requests
    # end
  end
end
