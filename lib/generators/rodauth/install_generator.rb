require 'rails/generators/base'
require 'securerandom'

require "#{__dir__}/concerns/accepts_table"
require "#{__dir__}/concerns/feature_options"

module Rodauth
  module Rails
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        include Concerns::AcceptsTable

        SEQUEL_ADAPTERS = {
          'postgresql' => RUBY_ENGINE == 'jruby' ? 'postgresql' : 'postgres',
          'mysql2' => RUBY_ENGINE == 'jruby' ? 'mysql' : 'mysql2',
          'sqlite3' => 'sqlite',
          'oracle_enhanced' => 'oracle',
          'sqlserver' => RUBY_ENGINE == 'jruby' ? 'mssql' : 'tinytds'
        }

        source_root "#{__dir__}/templates"
        namespace 'rodauth:install'

        class_option :account, type: :boolean, default: true, desc: '[CONFIG] create an account'
        # Include here to keep the account option above the feature options
        include Concerns::FeatureOptions

        def create_rodauth_initializer
          template 'config/initializers/rodauth.rb'
        end

        def create_rodauth_app
          template 'app/misc/rodauth_app.rb'
          template 'app/misc/rodauth_plugin.rb'
        end

        def generate_rodauth_account
          return unless options[:account]

          invoke "rodauth:account", [table], **invoke_options,
                                             migration_name: options[:migration_name]
        end

        def create_mailer
          return unless mails?

          copy_file 'app/mailers/rodauth_mailer.rb'
          directory 'app/views/rodauth_mailer'
        end

        def add_dev_config
          insert_into_file 'config/environments/development.rb',
                           "\n  config.action_mailer.default_url_options = { host: '127.0.0.1', port: ENV.fetch('PORT', 3000) }\n",
                           before: /^end/
        end

        def show_instructions
          readme 'INSTRUCTIONS' if behavior == :invoke
        end

        private

        def primary?
          options[:primary] != false
        end

        def sequel_activerecord_integration?
          defined?(ActiveRecord::Railtie) &&
            (!defined?(Sequel) || Sequel::DATABASES.empty?)
        end

        def sequel_adapter
          SEQUEL_ADAPTERS[activerecord_adapter] || activerecord_adapter
        end

        def activerecord_adapter
          if ActiveRecord::Base.respond_to?(:connection_db_config)
            ActiveRecord::Base.connection_db_config.adapter
          else
            ActiveRecord::Base.connection_config.fetch(:adapter)
          end
        end
      end
    end
  end
end
