Rails.application.routes.draw do
  root to: "test#root"

  controller :test do
    get :auth1
    get :auth2
    get :secondary
    get :sign_in
  end

  constraints Rodauth::Rails.authenticated do
    get "/authenticated" => "test#root"
  end
end
