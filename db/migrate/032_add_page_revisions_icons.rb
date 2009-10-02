class AddPageRevisionsIcons < ActiveRecord::Migration
  def self.up
    add_column :page_revisions, :icon_id, :integer
    add_column :page_revisions, :icon_hot_id, :integer
    add_column :page_revisions, :icon_disabled_id, :integer
    add_column :page_revisions, :icon_selected_id, :integer
  end

  def self.down
    remove_column :page_revisions, :icon_id
    remove_column :page_revisions, :icon_hot_id
    remove_column :page_revisions, :icon_disabled_id
    remove_column :page_revisions, :icon_selected_id
  end
end
