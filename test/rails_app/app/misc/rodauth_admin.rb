class RodauthAdmin < Rodauth::Rails::Auth
  configure do
    enable :login, :two_factor_base
    enable :webauthn_autofill unless RUBY_ENGINE == "jruby"
    prefix "/admin"
    rails_controller { Admin::RodauthController }
  end
end
