class Account < ApplicationRecord
  validates_presence_of :email
  include Rodauth::Rails.model
end
