class RodauthApp < Rodauth::Rails::App
  # auth configuration
  # configure RodauthMain

  route do |r|
    # this block is running inside of a roda route
    # see https://github.com/jeremyevans/roda#usage-

    # auth route configuration
    # r.rodauth

    # plugin route configuration
    # rodauth.load_memory # autologin remembered users

    # ==> Authenticating requests
    # Call `rodauth.require_account` for requests that you want to
    # require authentication for. For example:
    #
    # # authenticate /dashboard/* and /account/* requests
    # if r.path.start_with?("/dashboard") || r.path.start_with?("/account")
    #   rodauth.require_account
    # end
  end
end
