class AddSiteNodeNodePathIndex < ActiveRecord::Migration
  def self.up
    add_index :site_nodes,:node_path
    add_index :site_nodes,[:parent_id,:position], :name => 'parent_id_position'
    
    add_index :site_node_modifiers, [:site_node_id,:position], :name => 'site_node_id_pos'
    
    add_index :page_revisions, [ :revision_container_type, :revision_container_id, :revision, :language ], 
      :name => 'revision_index'
    add_index :page_paragraphs, [ :page_revision_id, :position ], :name => 'page_revision_id_index'
    
  end

  def self.down
  end
end
