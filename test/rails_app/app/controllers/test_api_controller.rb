class TestApiController < ActionController::API
  def auth_api
    rodauth.require_authentication

    render json: { success: true }
  end
end
