class RodauthController < ApplicationController
  before_action :before_route
  after_action :after_route
  around_action :around_route
  before_action :before_specific_route, only: [:create_account]

  rescue_from NotImplementedError do
    render plain: "rescued response", status: 500
  end

  private

  def before_route
    response.headers["X-Before-Action"] = "true"

    if params[:early_return]
      render plain: "early return", status: 201
    end
  end

  def after_route
    response.headers["X-After-Action"] = "true"
  end

  def around_route
    response.headers["X-Before-Around-Action"] = "true"
    yield
    response.headers["X-After-Around-Action"] = "true"
  end

  def before_specific_route
    response.header["X-Before-Specific-Action"] = "true"
  end

  def some_method
    "controller method"
  end
end
