class RodauthAdmin < Rodauth::Rails::Auth
  configure do
    prefix "/admin"
    rails_controller { Admin::RodauthController }
  end
end
