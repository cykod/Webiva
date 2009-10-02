class SiteTemplatesAddParentId < ActiveRecord::Migration
  def self.up
    add_column :site_templates, :parent_id, :integer
  end

  def self.down
    remove_column :site_templates, :parent_id
  end
end
