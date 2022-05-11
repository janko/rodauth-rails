<% if defined?(ActiveRecord::Railtie) -%>
class Account < ApplicationRecord
  include Rodauth::Rails.model
<% if ActiveRecord.version >= Gem::Version.new("7.0") -%>
  enum :status, unverified: 1, verified: 2, closed: 3
<% else -%>
  enum status: { unverified: 1, verified: 2, closed: 3 }
<% end -%>
end
<% else -%>
class Account < Sequel::Model
  include Rodauth::Rails.model
  plugin :enum
  enum :status, unverified: 1, verified: 2, closed: 3
end
<% end -%>
