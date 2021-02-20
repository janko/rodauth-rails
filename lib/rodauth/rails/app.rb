require "roda"
require "rodauth/rails/auth"

module Rodauth
  module Rails
    # The superclass for creating a Rodauth middleware.
    class App < Roda
      require "rodauth/rails/app/middleware"
      plugin Middleware

      plugin :hooks
      plugin :render, layout: false
      plugin :pass

      unless Rodauth::Rails.api_only?
        require "rodauth/rails/app/flash"
        plugin Flash
      end

      def self.configure(*args, **options, &block)
        auth_class = args.shift if args[0].is_a?(Class)
        name       = args.shift if args[0].is_a?(Symbol)

        fail ArgumentError, "need to pass optional Rodauth::Auth subclass and optional configuration name" if args.any?

        auth_class ||= Class.new(Rodauth::Rails::Auth)

        plugin :rodauth, auth_class: auth_class, name: name, csrf: false, flash: false, json: true, **options do
          instance_exec(&block) if block
        end
      end

      before do
        opts[:rodauths]&.each_key do |name|
          env[["rodauth", *name].join(".")] = rodauth(name)
        end
      end
    end
  end
end
