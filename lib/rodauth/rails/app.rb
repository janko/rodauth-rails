require "roda"
require "rodauth/rails/auth"

module Rodauth
  module Rails
    # The superclass for creating a Rodauth middleware.
    class App < Roda
      plugin :middleware, forward_response_headers: true do |middleware|
        middleware.class_eval do
          def self.inspect
            "#{superclass}::Middleware"
          end

          def inspect
            "#<#{self.class.inspect} request=#{request.inspect} response=#{response.inspect}>"
          end
        end
      end

      plugin :hooks
      plugin :render, layout: false

      def self.configure(*args, **options, &block)
        auth_class = args.shift if args[0].is_a?(Class)
        name       = args.shift if args[0].is_a?(Symbol)

        fail ArgumentError, "need to pass optional Rodauth::Auth subclass and optional configuration name" if args.any?

        auth_class ||= Class.new(Rodauth::Rails::Auth)

        plugin :rodauth, auth_class: auth_class, name: name, csrf: false, flash: false, json: true, **options, &block

        self::RodaRequest.include RequestMethods
      end

      before do
        opts[:rodauths]&.each_key do |name|
          env[["rodauth", *name].join(".")] = rodauth(name)
        end
      end

      after do
        rails_request.commit_flash
      end unless ActionPack.version < Gem::Version.new("5.0")

      def flash
        rails_request.flash
      end

      def rails_routes
        ::Rails.application.routes.url_helpers
      end

      def rails_request
        ActionDispatch::Request.new(env)
      end

      def self.rodauth!(name)
        rodauth(name) or fail ArgumentError, "unknown rodauth configuration: #{name.inspect}"
      end

      module RequestMethods
        def rodauth(name = nil)
          prefix = scope.rodauth(name).prefix

          if prefix.present? && remaining_path == path_info
            on prefix[1..-1] do
              super
              break # forward other `{prefix}/*` requests to the rails router
            end
          else
            super
          end
        end
      end
    end
  end
end
