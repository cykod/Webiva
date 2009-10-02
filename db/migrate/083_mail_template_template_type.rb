class MailTemplateTemplateType < ActiveRecord::Migration
  def self.up
    add_column :mail_templates, :template_type, :string, :default => 'site'
    add_column :mail_templates, :created_at, :datetime
    add_column :mail_templates, :updated_at, :datetime
    add_column :mail_templates, :category,:string
  end

  def self.down
    remove_column :mail_templates, :template_type
    remove_column :mail_templates, :created_at
    remove_column :mail_templates, :updated_at
    remove_column :mail_templates, :category
  end
end
