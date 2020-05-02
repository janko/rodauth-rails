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
end
