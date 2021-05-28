module Rodauth
  module Rails
    class Model < Module
      require "rodauth/rails/model/associations"

      VALIDATE_DEFAULTS = {
        login_presence: true,
        login_requirements: true,
        password_presence: true,
        password_requirements: true,
        password_confirmation: true,
      }

      def initialize(rodauth_class, validate: {}, association_options: {})
        validate.each_key { |key| VALIDATE_DEFAULTS.fetch(key) } # fail for invalid validate keys

        @rodauth_class = rodauth_class
        @validate = validate ? VALIDATE_DEFAULTS.merge(validate) : {}
        @association_options = association_options

        define_methods
      end

      def included(model)
        fail Rodauth::Rails::Error, "must be an Active Record model" unless model < ActiveRecord::Base

        define_associations(model)
        define_validations(model)
      end

      private

      def define_methods
        rodauth_class = @rodauth_class

        module_eval do
          attr_reader :password
          attr_accessor :password_confirmation if validate?(:password_confirmation)

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

          def validate_password_requirements
            unless rodauth.password_meets_requirements?(password.to_s) || password.to_s.empty?
              errors.add(:password, rodauth.send(:password_does_not_meet_requirements_message))
            end
          end if validate?(:password_requirements)

          def validate_password_confirmation
            if password_confirmation && password != password_confirmation
              errors.add(:password, rodauth.passwords_do_not_match_message)
            end
          end if validate?(:password_confirmation)

          def validate_login_requirements
            login = public_send(rodauth.login_column)
            unless rodauth.login_meets_requirements?(login.to_s) || login.to_s.empty?
              errors.add(rodauth.login_column, rodauth.send(:login_does_not_meet_requirements_message))
            end
          end if validate?(:login_requirements)

          def password_changed?
            instance_variable_defined?(:@password) || new_record?
          end

          define_method :rodauth do
            @rodauth ||= (
              rodauth = rodauth_class.allocate
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

      def define_validations(model)
        model.validates_presence_of rodauth.login_column if validate?(:login_presence)
        model.validate :validate_login_requirements if validate?(:login_requirements)

        model.validates_presence_of :password, if: :password_changed? if validate?(:password_presence)
        model.validate :validate_password_requirements, if: :password_changed? if validate?(:password_requirements)
        model.validate :validate_password_confirmation, if: :password_changed? if validate?(:password_confirmation)
      end

      def feature_associations
        Rodauth::Rails::Model::Associations.call(rodauth)
      end

      def validate?(name)
        @validate.fetch(name)
      end

      def association_options(name)
        options = @association_options
        options = options.call(name) if options.respond_to?(:call)
        options || {}
      end

      def rodauth
        @rodauth_class.allocate
      end
    end
  end
end
