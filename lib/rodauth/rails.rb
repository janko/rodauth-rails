require "rodauth/rails/version"
require "rodauth/rails/railtie"
require "rodauth/model"

module Rodauth
  module Rails
    class Error < StandardError
    end

    # This allows avoiding loading Rodauth at boot time.
    autoload :App, "rodauth/rails/app"
    autoload :Auth, "rodauth/rails/auth"
    autoload :Mailer, "rodauth/rails/mailer"

    @app = nil
    @middleware = true
    @tilt = true

    class << self
      def lib(**options, &block)
        c = Class.new(Rodauth::Rails::App)
        c.configure(json: false, **options) do
          enable :internal_request
          instance_exec(&block)
        end
        c.freeze
        c.rodauth
      end

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
            @account = account.attributes_before_type_cast.symbolize_keys
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

      # Routing constraint that requires authenticated account.
      def authenticate(name = nil, &condition)
        lambda do |request|
          rodauth = request.env.fetch ["rodauth", *name].join(".")
          rodauth.require_account
          condition.nil? || condition.call(rodauth)
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

      def configure
        yield self
      end

      attr_writer :app
      attr_writer :middleware
      attr_writer :tilt

      def app
        fail Rodauth::Rails::Error, "app was not configured" unless @app

        @app.constantize
      end

      def middleware?
        @middleware
      end

      def tilt?
        @tilt
      end
    end
  end
end
