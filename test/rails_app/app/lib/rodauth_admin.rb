class RodauthAdmin < Rodauth::Rails::Auth
  configure do
    prefix "/admin"
  end
end
