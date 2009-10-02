class AddSiteNodeInfo < ActiveRecord::Migration
  def self.up
    add_column :site_nodes, :follow_links, :integer, :default => 1
    add_column :site_nodes, :index_page, :integer, :default => 1
    add_column :site_nodes, :cache_page, :boolean, :default => true
    add_column :site_nodes, :include_in_sitemap, :boolean, :default => true
  end

  def self.down
    remove_column :site_nodes, :follow_links
    remove_column :site_nodes, :index_page
    remove_column :site_nodes, :cache_page
    remove_column :site_nodes, :include_in_sitemap
  end
end
