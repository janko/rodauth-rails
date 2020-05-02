require "sequel/core"

DB = Sequel.sqlite(test: false)
DB.extension :activerecord_connection
