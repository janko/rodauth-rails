class TestController < ApplicationController
  def root
    render :template
  end

  def auth1
    render :template
  end

  def auth2
    rodauth.require_authentication

    render :template
  end

  def secondary
    rodauth(:admin).require_authentication

    render :template
  end

  def sign_in
    rodauth.account_from_login(Account.first.email)

    rodauth_response do
      rodauth.login("test")
    end

    headers["X-After"] = "true"
  end
end
