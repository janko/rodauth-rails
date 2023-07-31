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
      plugin :pass

      def self.configure(*args, **options, &block)
        auth_class = args.shift if args[0].is_a?(Class)
        auth_class ||= Class.new(Rodauth::Rails::Auth)
        name = args.shift if args[0].is_a?(Symbol)

        fail ArgumentError, "need to pass optional Rodauth::Auth subclass and optional configuration name" if args.any?

        # we'll render Rodauth's built-in view templates within Rails layouts
        plugin :render, layout: false unless options[:render] == false

        plugin :rodauth, auth_class: auth_class, name: name, csrf: false, flash: false, json: true, **options, &block

        # we need to do it after request methods from rodauth have been included
        self::RodaRequest.include RequestMethods
      end

      before do
        opts[:rodauths]&.each_key do |name|
          env[["rodauth", *name].join(".")] = rodauth(name)
        end
      end

      after do
        rails_request.commit_flash
      end

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

      # The newrelic_rpm gem expects this when we pass the roda class as
      # :controller in instrumentation payload.
      def self.controller_path
        name.underscore
      end

      module RequestMethods
        # Automatically route the prefix if it hasn't been routed already. This
        # way people only have to update prefix in their Rodauth configurations.
        def rodauth(name = nil)
          prefix = scope.rodauth(name).prefix

          if prefix.present? && remaining_path == path_info
            on prefix[1..-1] do
              super
              pass # forward other {prefix}/* requests downstream
            end
          else
            super
          end
        end

        # The Rack input might not be rewindable, so ensure we parse the JSON
        # request body in Rails, and avoid parsing it again in Roda.
        def POST
          if content_type =~ /json/
            env["roda.json_params"] = scope.rails_request.POST.to_hash
          end
          super
        end

        # When calling a Rodauth method that redirects inside the Rails
        # router, Roda's after hook that commits the flash would never get
        # called, so we make sure to commit the flash beforehand.
        def redirect(*)
          scope.rails_request.commit_flash
          super
        end
      end
    end
  end
end
