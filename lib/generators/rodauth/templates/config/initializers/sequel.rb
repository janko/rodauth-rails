require "sequel/core"

# initialize the appropriate Sequel adapter without creating a connection
DB = Sequel.<%= sequel_adapter %>(test: false)
# have Sequel use ActiveRecord's connection for database interaction
DB.extension :activerecord_connection
