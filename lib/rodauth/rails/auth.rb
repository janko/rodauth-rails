require "rodauth"
require "rodauth/rails/feature"

module Rodauth
  module Rails
    # Base auth class that applies some changes to the default configuration.
    class Auth < Rodauth::Auth
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
