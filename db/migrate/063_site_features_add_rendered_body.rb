class SiteFeaturesAddRenderedBody < ActiveRecord::Migration
  def self.up
    add_column :site_features, :body_html, :text
  end

  def self.down
    remove_column :site_features, :body_html
  end
end
