class AddSiteTemplateHead < ActiveRecord::Migration
  def self.up
    add_column :site_templates, :head, :text
  end

  def self.down
    remove_column :site_templates, :head
  end
end
