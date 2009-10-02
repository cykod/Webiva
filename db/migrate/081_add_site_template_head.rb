class AddSiteTemplateHead < ActiveRecord::Migration
  def self.up
    add_column :site_templates, :head,:text, :default => ''
  end

  def self.down
    remove_column :site_templates, :head
  end
end
