class Account < ApplicationRecord
  include Rodauth::Rails.model
  validates_presence_of :email
end
