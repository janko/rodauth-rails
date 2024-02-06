Rails.application.routes.draw do
  root to: "test#root"

  controller :test do
    get :auth1
    get :auth2
    get :basic_auth
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
