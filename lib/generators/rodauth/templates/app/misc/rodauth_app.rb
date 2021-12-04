class RodauthApp < Rodauth::Rails::App
  # primary configuration
  configure RodauthMain

  # secondary configuration
  # configure RodauthAdmin, :admin

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
