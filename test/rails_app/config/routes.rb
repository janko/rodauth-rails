Rails.application.routes.draw do
  root to: "test#root"

  rodauth
  rodauth(:admin)

  controller :test do
    get :auth1
    get :auth2
    get :secondary
    get :auth_json
    get :sign_in
    get :roda
  end

  get "/admin/custom2" => "admin/rodauth#custom"

  constraints Rodauth::Rails.authenticate do
    get "/authenticated" => "test#root"
  end
end
