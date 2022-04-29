module Rodauth
  module Rails
    class Model < Module
      ASSOCIATION_TYPES = { one: :has_one, many: :has_many }

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
        rodauth = @auth_class.allocate.freeze

        attr_reader :password

        define_method(:password=) do |password|
          @password = password
          password_hash = rodauth.send(:password_hash, password) if password
          set_password_hash(password_hash)
        end

        define_method(:set_password_hash) do |password_hash|
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
      end

      def define_associations(model)
        define_password_hash_association(model) unless rodauth.account_password_hash_column

        rodauth.associations.each do |association|
          define_association(model, **association, type: ASSOCIATION_TYPES.fetch(association[:type]))
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

        unless name == :authentication_audit_logs
          dependent = type == :has_many ? :delete_all : :delete
        end

        model.public_send type, name, scope,
          class_name: associated_model.name,
          foreign_key: foreign_key,
          dependent: dependent,
          inverse_of: :account,
          **options,
          **association_options(name)
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
