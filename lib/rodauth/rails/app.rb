require "roda"

module Rodauth
  module Rails
    # The superclass for creating a Rodauth middleware.
    class App < Roda
      require "rodauth/rails/app/flash"

      plugin :middleware
      plugin :hooks
      plugin :render, layout: false

      plugin Flash

      def self.rodauth(name = nil, **options, &block)
        plugin :rodauth, name: name, csrf: false, flash: false, **options do
          # load the Rails integration
          enable :rails

          # database functions are more complex to set up, so disable them by default
          use_database_authentication_functions? false

          # avoid having to set deadline values in column default values
          set_deadline_values? true

          # use HMACs for additional security
          hmac_secret { ::Rails.application.secrets.secret_key_base }

          # evaluate user configuration
          instance_exec(&block)
        end
      end

      before do
        opts[:rodauths]&.each do |name, _|
          if name
            env["rodauth.#{name}"] = rodauth(name)
          else
            env["rodauth"] = rodauth
          end
        end
      end
    end
  end
end
