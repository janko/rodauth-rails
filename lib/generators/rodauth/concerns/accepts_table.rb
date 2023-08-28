module Rodauth
  module Rails
    module Generators
      module Concerns
        module AcceptsTable
          def self.included(base)
            base.send :argument, :name, type: :string, default: 'account', desc: 'Name of the account model'
            base.send :class_option, :migration_name, type: :string, desc: 'Name of the generated'
          end

          private

          def table
            @table ||= name.underscore.pluralize
          end

          def table_prefix
            @table_prefix ||= name.underscore.singularize
          end
        end
      end
    end
  end
end
