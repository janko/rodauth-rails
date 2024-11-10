class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def current_account
    rodauth.rails_account
  end
  helper_method :current_account
end
