
class ContentNodeMigration < ActiveRecord::Migration
  def self.up
    drop_table :content_model_nodes

    create_table :content_types, :force => true do |t|
      t.string :component
      t.string :container_type # For multiple Blogs/etc, eg. BlogBlog
      t.integer :container_id # E.g. 1
      t.string :content_name # Eg My Blog
      t.string :content_type, :limit => 128
      t.integer :detail_site_node_id
      t.integer :list_site_node_id
      t.string :title_field
      t.string :url_field
      t.boolean :search_results, :default => true
      t.boolean :editable, :default => true
      t.integer :preview_publication_id
      t.integer :detail_publication_id
      t.timestamps
    end
    
    create_table :content_nodes, :force => true do |t|
      t.integer :content_type_id

      t.string :node_type
      t.integer :node_id
      t.integer :author_id
      t.integer :last_editor_id
      t.string :content_url_override
      t.boolean :sticky, :default => false
      t.boolean :published,  :default => true
      t.boolean :promoted, :default => false
      t.timestamps
    end

    add_index :content_nodes, [ :node_type, :node_id ], :name => 'node_index'
    add_index :content_nodes, [ :created_at, :node_type ], :name => 'date_index'    

    
    create_table :content_node_revisions, :force => true do |t|
      t.integer :content_node_id
      t.text :revision_data
      t.timestamps
      t.integer :user_id
    end
    
    add_index :content_node_revisions, [:content_node_id], :name => 'Content Node'
    
    
    create_table :linked_content_items, :force => true do |t|
      t.string :content_type, :limit => 128
      t.integer :content_id
      t.string :link_type, :limit => 128
      t.string :linked_content_type
      t.integer :linked_content_id
    end
    
    add_index :linked_content_items, [:content_type, :content_id, :link_type ], :name => 'Node Index'
    
    
    create_table :access_tokens, :force => true do |t|
      t.string :token_name, :size => 32
      t.boolean :editor, :default => false
    end
    
    create_table :end_user_tokens, :force => true do |t|
      t.integer :access_token_id
      t.integer :end_user_id
      t.datetime :valid_until
    end
    
    add_index :end_user_tokens, [ :end_user_id, :valid_until ], :name => 'user_index'
    add_index :end_user_tokens, [ :access_token_id ], :name => 'token_index'
    
    
    add_column :content_model_fields, :field_module, :string, :default => 'content/core_field'
    
    add_index :content_model_fields, :content_model_id, :name => 'content_model'
    
    add_column :content_publication_fields, :publication_field_module, :string
    add_column :content_publication_fields, :publication_field_type, :string
    
    add_column :content_publications, :publication_module, :string, :default => 'content/core_publication'
    
    create_table :content_model_features do |t|
      t.integer :content_model_id
      t.string :feature_handler
      t.integer :position
      t.text :feature_options
      t.boolean :model_generator_callback,:default => false
      t.boolean :more_table_actions_callback, :default => false
      t.boolean :table_columns_callback, :default => false
      t.boolean :header_actions_callback, :default => false
      t.boolean :add_migration_callback, :default => false
      t.boolean :remove_migration_callback, :default => false
    end
    
  end

  def self.down
    
    drop_table :end_user_tokens
    drop_table :access_tokens
    drop_table :linked_content_items
    drop_table :content_node_revisions
    drop_table :content_nodes
    drop_table :content_types

    create_table :content_model_nodes, :force => true do |t|
      t.string :node_type
      t.integer :node_id
      t.integer :end_user_id
      t.timestamps
    end
    
    remove_column :content_model_fields, :field_module
    remove_index :content_model_fields, :name => 'content_model'
    
    remove_column :content_publication_fields,:publication_field_module
    remove_column :content_publication_fields,:publication_field_type
    
    remove_column :content_publications, :publication_module
    
    drop_table :content_model_features
  end
end
