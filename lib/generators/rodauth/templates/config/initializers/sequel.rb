require "sequel/core"

# initialize the appropriate Sequel adapter without creating a connection
<% case adapter -%>
<% when "postgresql" -%>
DB = Sequel.postgres(test: false)
<% when "mysql2" -%>
DB = Sequel.mysql2(test: false)
<% when "sqlite3" -%>
DB = Sequel.sqlite(test: false)
<% end -%>
# have Sequel use ActiveRecord's connection for database interaction
DB.extension :activerecord_connection
