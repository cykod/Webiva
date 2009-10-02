class AddSiteFeatureOptions < ActiveRecord::Migration
  def self.up
    add_column :site_features, :options, :text
  end

  def self.down
    remove_column :site_features, :options
  end
end
