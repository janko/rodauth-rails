require "sequel/core"

# initialize the appropriate Sequel adapter without creating a connection
<%- if RUBY_ENGINE == "jruby" -%>
DB = Sequel.connect("jdbc:<%= sequel_adapter %>://", test: false)
<% else -%>
DB = Sequel.<%= sequel_adapter %>(test: false)
<% end -%>
# have Sequel use ActiveRecord's connection for database interaction
DB.extension :activerecord_connection
