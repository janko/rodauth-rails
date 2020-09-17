require "sequel/core"

DB = Sequel.connect("#{"jdbc:" if RUBY_ENGINE == "jruby"}sqlite://", extensions: :activerecord_connection)
