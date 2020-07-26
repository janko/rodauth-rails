require "sequel/core"

DB = Sequel.connect("#{"jdbc:" if RUBY_ENGINE == "jruby"}sqlite://", test: false)
DB.extension :activerecord_connection
