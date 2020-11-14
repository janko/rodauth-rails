class <%= migration_class_name %> < ActiveRecord::Migration<%= migration_version %>
  def change
<%= migration_content -%>
  end
end
