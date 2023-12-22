class RodauthApp < Rodauth::Rails::App
  configure RodauthMain
  configure RodauthAdmin, :admin
  configure RodauthMultiTenant, :multi_tenant

  plugin :symbol_matchers

  # Allow UUID characters in path_key
  symbol_matcher :path_key, /([A-Z0-9_-]+)/xi

  configure(:jwt) do
    enable :jwt, :create_account, :verify_account
    rails_controller { ActionController::API }
    only_json? true
    prefix "/jwt"
    jwt_secret "secret"
    account_status_column :status
  end

  configure(:json) do
    enable :json, :create_account, :verify_account, :two_factor_base
    rails_controller { ActionController::API }
    only_json? true
    prefix "/json"
    account_status_column :status
  end

  route do |r|
    rodauth.load_memory

    r.rodauth
    r.rodauth(:admin)
    r.on("multi/tenant") do
      r.on(:path_key) do |path_key|
        # In a real life application you'd only proceed to rodauth routing if a tenant was found.
        # We'll mimic that possibility by skipping a /banana path-key
        next if path_key == "banana"

        r.env[:path_key] = path_key
        rodauth(:multi_tenant).path_key = path_key

        r.rodauth(:multi_tenant)
        next
      end
      next
    end

    r.on("jwt") { r.rodauth(:jwt) }
    r.on("json") { r.rodauth(:json) }

    r.on("assets") { "" }
    r.get("admin/custom1") { "Custom admin route" }

    if r.path == rails_routes.auth1_path
      rodauth.require_account
    end
  end
end
