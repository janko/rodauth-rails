require "sequel/core"

# initialize Sequel and have it reuse Active Record's database connection
DB = Sequel.connect("<%= sequel_uri_scheme %>://", extensions: :activerecord_connection)
