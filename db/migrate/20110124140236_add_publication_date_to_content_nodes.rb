class AddPublicationDateToContentNodes < ActiveRecord::Migration
  def self.up
    add_column :content_nodes, :published_at, :datetime
    add_index :content_node_values, :content_node_id, :name => 'node_id_index'
  end

  def self.down
    remove_column :content_nodes, :published_at
    remove_index :content_node_values, :name => 'node_id_index'
  end
end
