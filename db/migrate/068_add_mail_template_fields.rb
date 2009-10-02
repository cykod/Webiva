class AddMailTemplateFields < ActiveRecord::Migration
  def self.up
    add_column :mail_templates, :archived, :boolean, :default => false
    add_column :mail_templates, :master, :boolean, :default => false
    add_column :mail_templates, :site_template_id, :integer 
    
    add_column :site_templates, :template_type, :string, :default => 'site'
  end

  def self.down
    remove_column :mail_templates, :archived
    remove_column :mail_templates, :master
    remove_column :mail_templates, :site_template_id
    
    remove_column :site_templates, :template_type
  end
end
