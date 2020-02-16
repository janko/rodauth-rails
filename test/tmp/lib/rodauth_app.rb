class RodauthApp < Rodauth::Rails::App
  rodauth do
    # list of authentication features that are activated
    enable :create_account, :verify_account, :verify_account_grace_period,
      :login, :remember, :logout,
      :reset_password, :change_password, :change_password_notify,
      :change_login, :verify_login_change,
      :close_account

    # automatically remember logged in users
    after_login do
      remember_login
    end

    # Some other examples of what you can configure:
    #
    #   # subject prefix for emails sent by Rodauth
    #   email_subject_prefix "[MyApp] "
    #   # from header for emails sent by Rodauth
    #   email_from "noreply@myapp.com"
    #
    #   # validations for any additional fields in the create account form
    #   before_create_account do
    #     throw_error_status(422, "name", "must be present") if param("name").empty?
    #   end
    #
    #   # create a user profile record associated to the created account
    #   after_create_account do
    #     db.after_commit do
    #       Profile.create!(account_id: account[:id], name: param("name"))
    #     end
    #   end
    #
    #   # redirect to home page after logout
    #   logout_redirect "/"
    #
    #   after_close_account do
    #     # do any additional cleanup after the account is closed
    #   end
    #
    # See the Rodauth documentation for list of available configuration options:
    # http://rodauth.jeremyevans.net/documentation.html
  end

  route do |r|
    rodauth.load_memory # autologin remembered users

    r.rodauth # route rodauth requests

    # Exit the routing block for requests that don't require authentication.
    # Some examples:
    #
    #   # only require authentication for "/dashboard/*" routes
    #   next unless r.path.start_with?("/dashboard")
    #
    #   # skip authentication for webhooks
    #   next if r.path.start_wit?("/webhooks")
    #
    #   # skip authentication for admins
    #   next unless session[:admin]
    #
    # The following skips authentication for all routes:
    next unless r.path.start_with?("/")

    rodauth.require_authentication # redirect to login if not authenticated

    nil # forward the request to the Rails app
  end
end
