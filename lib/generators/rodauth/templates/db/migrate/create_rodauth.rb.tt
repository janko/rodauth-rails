<% if defined?(::ActiveRecord::Railtie) -%>
class <%= migration_class_name %> < ActiveRecord::Migration<%= migration_version %>
  def change
<%= migration_content -%>
  end
end
<% else -%>
Sequel.migration do
  change do
<%= migration_content -%>
  end
end
<% end -%>
