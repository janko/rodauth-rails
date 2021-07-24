module Rodauth
  module Rails
    class Model < Module
      require "rodauth/rails/model/associations"

      def initialize(auth_class, association_options: {})
        @auth_class = auth_class
        @association_options = association_options

        define_methods
      end

      def included(model)
        fail Rodauth::Rails::Error, "must be an Active Record model" unless model < ActiveRecord::Base

        define_associations(model)
      end

      private

      def define_methods
        auth_class = @auth_class

        module_eval do
          attr_reader :password

          def password=(password)
            @password = password
            password_hash = rodauth.send(:password_hash, password) if password
            set_password_hash(password_hash)
          end

          def set_password_hash(password_hash)
            if rodauth.account_password_hash_column
              public_send(:"#{rodauth.account_password_hash_column}=", password_hash)
            else
              if password_hash
                record = self.password_hash || build_password_hash
                record.public_send(:"#{rodauth.password_hash_column}=", password_hash)
              else
                self.password_hash&.mark_for_destruction
              end
            end
          end

          private

          define_method :rodauth do
            @rodauth ||= (
              rodauth = auth_class.allocate
              rodauth.instance_variable_set(:@account, attributes.symbolize_keys)
              rodauth
            )
          end
        end
      end

      def define_associations(model)
        define_password_hash_association(model) unless rodauth.account_password_hash_column

        feature_associations.each do |association|
          define_association(model, **association)
        end
      end

      def define_password_hash_association(model)
        password_hash_id_column = rodauth.password_hash_id_column
        scope = -> { select(password_hash_id_column) } if rodauth.send(:use_database_authentication_functions?)

        define_association model,
          type: :has_one,
          name: :password_hash,
          table: rodauth.password_hash_table,
          foreign_key: password_hash_id_column,
          scope: scope,
          autosave: true
      end

      def define_association(model, type:, name:, table:, foreign_key:, scope: nil, **options)
        associated_model = Class.new(model.superclass)
        associated_model.table_name = table
        associated_model.belongs_to :account,
          class_name: model.name,
          foreign_key: foreign_key,
          inverse_of: name

        model.const_set(name.to_s.singularize.camelize, associated_model)

        model.public_send type, name, scope,
          class_name: associated_model.name,
          foreign_key: foreign_key,
          dependent: :destroy,
          inverse_of: :account,
          **options,
          **association_options(name)
      end

      def feature_associations
        Rodauth::Rails::Model::Associations.call(rodauth)
      end

      def association_options(name)
        options = @association_options
        options = options.call(name) if options.respond_to?(:call)
        options || {}
      end

      def rodauth
        @auth_class.allocate
      end
    end
  end
end
