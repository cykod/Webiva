class UpdateSystemIssues < ActiveRecord::Migration
  def self.up
    add_column :system_issues, :error_type, :string
    add_column :system_issues, :error_location, :string
    add_column :system_issues, :code_location, :string
    add_column :system_issues, :parent_id, :integer
    add_column :system_issues, :children_count, :integer
  end

  def self.down
    remove_column :system_issues, :error_type
    remove_column :system_issues, :error_location
    remove_column :system_issues, :code_location
    remove_column :system_issues, :parent_id
    remove_column :system_issues, :children_count
  end
end
