require "rodauth"
require "rodauth/rails/feature"

module Rodauth
  module Rails
    # Base auth class that applies some default configuration and supports
    # multi-level inheritance.
    class Auth < Rodauth::Auth
      # apply default configuration
      configure do
        enable :rails

        # database functions are more complex to set up, so disable them by default
        use_database_authentication_functions? false

        # avoid having to set deadline values in column default values
        set_deadline_values? true

        # use HMACs for additional security
        hmac_secret { Rodauth::Rails.secret_key_base }
      end

      def self.instance(account: nil, **options)
        unless features.include?(:internal_request)
          fail Rodauth::Rails::Error, "Rodauth::Rails::Auth.instance requires internal_request feature to be enabled"
        end

        if account
          options[:account_id] = account.id
        end

        internal_request_eval(options) do
          if defined?(ActiveRecord::Base) && account.is_a?(ActiveRecord::Base)
            @account = account.attributes.symbolize_keys
          elsif defined?(Sequel::Model) && account.is_a?(Sequel::Model)
            @account = account.values
          end

          self
        end
      end

      def self.inherited(subclass)
        super
        superclass = self
        subclass.class_eval do
          @roda_class = Rodauth::Rails.app
          @features = superclass.features.clone
          @routes = superclass.routes.clone
          @route_hash = superclass.route_hash.clone
          @configuration = superclass.instance_variable_get(:@configuration).clone
          @configuration.instance_variable_set(:@auth, self)
        end
      end
    end
  end
end
