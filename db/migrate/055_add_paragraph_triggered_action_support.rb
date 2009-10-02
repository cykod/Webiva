class AddParagraphTriggeredActionSupport < ActiveRecord::Migration
  def self.up
    add_column :page_paragraphs, :view_action_count, :integer, :default => 0
    add_column :page_paragraphs, :update_action_count, :integer, :default => 0
  end

  def self.down
    remove_column :page_paragraphs, :view_action_count, :integer, :default => 0
    remove_column :page_paragraphs, :update_action_count, :integer, :default => 0
  end
end
