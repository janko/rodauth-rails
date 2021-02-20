require "rodauth"
require "rodauth/rails/feature"

module Rodauth
  module Rails
    # Base auth class that applies some default configuration and supports
    # multi-level inheritance.
    class Auth < Rodauth::Auth
      class << self
        attr_writer :features
        attr_writer :routes
        attr_accessor :configuration
      end

      def self.inherited(auth_class)
        super
        auth_class.roda_class = Rodauth::Rails.app
        auth_class.features = features.dup
        auth_class.routes = routes.dup
        auth_class.route_hash = route_hash.dup
        auth_class.configuration = configuration.clone
        auth_class.configuration.instance_variable_set(:@auth, auth_class)
      end

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
    end
  end
end
