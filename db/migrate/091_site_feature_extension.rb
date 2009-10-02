
class SiteFeatureExtension < ActiveRecord::Migration
  def self.up

    add_column :site_features, :admin_user_id, :integer
    add_column :site_features, :css, :text
    add_column :site_features, :category, :string
    add_column :site_features, :archived, :boolean, :default => false
    add_column :site_features, :image_folder_id,:integer
    add_column :site_features, :rendered_css,:text
    add_column :site_features, :created_at, :datetime
    add_column :site_features, :updated_at, :datetime


    execute "UPDATE site_features SET updated_at = NOW(),created_at = NOW() WHERE 1"
    
  end

  def self.down
    remove_column :site_features, :admin_user_id
    remove_column :site_features, :css
    remove_column :site_features, :category
    remove_column :site_features, :archived
    remove_column :site_features, :image_folder_id
    remove_column :site_features, :rendered_css
    remove_column :site_features, :created_at
    remove_column :site_features, :updated_at
  end
end
