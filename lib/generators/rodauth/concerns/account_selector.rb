module Rodauth
  module Rails
    module Generators
      module Concerns
        module AccountSelector
          def self.included(base)
            base.send :argument, :account_name, type: :string, default: 'account', desc: '[CONFIG] name of the account model. '
            base.send :class_option, :migration_name, type: :string, desc: '[CONFIG] name of the generated migration file'
          end

          private

          def table
            @table ||= account_name.underscore.pluralize
          end

          def table_prefix
            @table_prefix ||= account_name.underscore.singularize
          end
        end
      end
    end
  end
end
