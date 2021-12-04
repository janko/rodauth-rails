class RodauthAdmin < Rodauth::Rails::Auth
  configure do
    enable :login
    prefix "/admin"
    rails_controller { Admin::RodauthController }
  end
end
