class EndUserOptions < ActiveRecord::Migration
  def self.up
    add_column :end_users, :options, :text
    remove_column :site_modules, :options_data
    remove_column :site_modules, :description
    remove_column :site_modules, :module_name
    add_column :site_modules, :options, :text
    
  end

  def self.down
  end
end
