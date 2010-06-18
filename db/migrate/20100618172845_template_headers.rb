class TemplateHeaders < ActiveRecord::Migration
  def self.up
    add_column :site_templates, :doctype,:string 
    add_column :site_templates, :partial, :boolean, :default => false
  end

  def self.down
    remove_column :site_templates, :doctype
    remove_column :site_templates, :partial
  end
end
