require "sequel-activerecord-adapter"

# creates a Sequel "connection" that reuses the existing ActiveRecord connection
DB = Sequel.activerecord
