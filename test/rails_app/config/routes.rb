Rails.application.routes.draw do
  root to: "test#root"

  controller :test do
    get :auth1
    get :auth2
    get :secondary
  end

  controller :test_api do
    get :auth_api
  end
end
