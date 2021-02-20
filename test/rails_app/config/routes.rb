Rails.application.routes.draw do
  root to: "test#root"

  controller :test do
    get :auth1
    get :auth2
    get :secondary

    constraints(->(r) {  r.env['rodauth'].require_authentication}) do
      get :under_constraints
    end
  end
end
