class Admin::RodauthController < ApplicationController
  def custom
    render plain: "Custom admin route"
  end
end
