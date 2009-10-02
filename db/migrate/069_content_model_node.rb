class ContentModelNode < ActiveRecord::Migration
  def self.up
    create_table :content_model_nodes, :force => true do |t|
      t.string :node_type
      t.integer :node_id
      t.integer :end_user_id
      t.timestamps
    end
    
    add_index :content_model_nodes, [ :node_type, :node_id ], :name => 'node_index'
    add_index :content_model_nodes, [ :created_at, :node_type ], :name => 'date_index'
    
    add_column :content_models, :create_nodes, :boolean, :default => true
    add_column :content_models, :email_field, :string
    add_column :content_models, :last_name_field, :string
    add_column :content_models, :first_name_field, :string
  end

  def self.down
    drop_table :content_model_nodes
    
    remove_column :content_models, :create_nodes
    remove_column :content_models, :email_field
    remove_column :content_models, :last_name_field
    remove_column :content_models, :first_name_field
  end
end
