class RodauthAdmin < Rodauth::Rails::Auth
  configure do
    enable :login, :webauthn_autofill
    prefix "/admin"
    rails_controller { Admin::RodauthController }
  end
end
