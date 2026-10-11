class RodauthAdmin < Rodauth::Rails::Auth
  configure do
    enable :login, :two_factor_base
    enable :webauthn_autofill, :webauthn_modify_email unless RUBY_ENGINE == "jruby"
    prefix "/admin"
    rails_controller { Admin::RodauthController }
    already_logged_in { redirect login_redirect }
  end
end
