class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def current_account
    Account.find(rodauth.session_value)
  end
  helper_method :current_account
end
