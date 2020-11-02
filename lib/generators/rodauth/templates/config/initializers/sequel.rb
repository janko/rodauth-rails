require "sequel/core"

# initialize Sequel and have it reuse Active Record's database connection
<% if RUBY_ENGINE == "jruby" -%>
DB = Sequel.connect("jdbc:<%= sequel_adapter %>://", extensions: :activerecord_connection, test: false)
<% else -%>
DB = Sequel.<%= sequel_adapter %>(extensions: :activerecord_connection, test: false)
<% end -%>
