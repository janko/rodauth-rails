require "rodauth/rails/version"
require "rodauth/rails/railtie"
require "rodauth/model"

module Rodauth
  module Rails
    class Error < StandardError
    end

    # This allows the developer to avoid loading Rodauth at boot time.
    autoload :App, "rodauth/rails/app"
    autoload :Auth, "rodauth/rails/auth"
    autoload :Model, "rodauth/rails/model"

    @app = nil
    @middleware = true

    class << self
      def rodauth(name = nil, account: nil, **options)
        auth_class = app.rodauth!(name)

        unless auth_class.features.include?(:internal_request)
          fail Rodauth::Rails::Error, "Rodauth::Rails.rodauth requires internal_request feature to be enabled"
        end

        if account
          options[:account_id] = account.id
        end

        instance = auth_class.internal_request_eval(options) do
          if defined?(ActiveRecord::Base) && account.is_a?(ActiveRecord::Base)
            @account = account.attributes.symbolize_keys
          elsif defined?(Sequel::Model) && account.is_a?(Sequel::Model)
            @account = account.values
          end
          self
        end

        # clean up inspect output
        instance.remove_instance_variable(:@internal_request_block)
        instance.remove_instance_variable(:@internal_request_return_value)

        instance
      end

      def model(name = nil, **options)
        Rodauth::Model.new(app.rodauth!(name), **options)
      end

      # routing constraint that requires authentication
      def authenticated(name = nil, &condition)
        lambda do |request|
          rodauth = request.env.fetch ["rodauth", *name].join(".")
          rodauth.require_authentication
          rodauth.authenticated? && (condition.nil? || condition.call(rodauth))
        end
      end

      if ::Rails.gem_version >= Gem::Version.new("5.2")
        def secret_key_base
          ::Rails.application.secret_key_base
        end
      else
        def secret_key_base
          ::Rails.application.secrets.secret_key_base
        end
      end

      if ::Rails.gem_version >= Gem::Version.new("5.0")
        def api_only?
          ::Rails.application.config.api_only
        end
      else
        def api_only?
          false
        end
      end

      def configure
        yield self
      end

      attr_writer :app
      attr_writer :middleware

      def app
        fail Rodauth::Rails::Error, "app was not configured" unless @app

        @app.constantize
      end

      def middleware?
        @middleware
      end
    end
  end
end
