class RemoveContentPublicationActions < ActiveRecord::Migration
  def self.up
    remove_column :content_publications, :actions
    add_column :content_publications, :view_action_count, :integer, :default => 0
    add_column :content_publications, :update_action_count, :integer, :default => 0
  end

  def self.down
    add_column :content_publications, :actions, :text
    remove_column :content_publications, :view_action_count 
    remove_column :content_publications, :update_action_count 
  end
end
