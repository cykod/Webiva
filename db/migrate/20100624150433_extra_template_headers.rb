class ExtraTemplateHeaders < ActiveRecord::Migration
  def self.up
    add_column :site_templates, :lightweight, :boolean, :default => false
    add_column :site_templates, :preprocessor, :string
    add_column :site_features,  :preprocessor, :string
  end

  def self.down
    remove_column :site_templates, :lightweight
    remove_column :site_templates, :preprocessor
    remove_column :site_features, :preprocessor
  end
end
