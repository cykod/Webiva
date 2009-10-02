class AddSiteNodeArchived < ActiveRecord::Migration
  def self.up
    add_column :site_nodes, :archived, :boolean, :default => false
  end

  def self.down
    remove_column :site_nodes, :archived
  end
end
