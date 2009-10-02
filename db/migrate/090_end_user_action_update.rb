
class EndUserActionUpdate < ActiveRecord::Migration
  def self.up
  
   create_table :end_user_actions, :force => true do |t|
      t.integer :end_user_id
      t.integer :admin_user_id
      t.integer :level, :default => 1 #0-admin, #1 - data, #2-login/access,  #3-action, #4 - information,  #5-conversion
      t.datetime :created_at    
      t.datetime :action_at
      t.string :target_type
      t.integer :target_id
      t.boolean :custom,:default => false
      t.string :renderer
      t.string :action
      t.string :path
      t.string :identifier
    end
    
    add_index :end_user_actions, [:end_user_id, :action_at], :name => 'user_date_index'
    add_index :end_user_actions, [:renderer, :action, :action_at], :name => 'action_index'
    add_index :end_user_actions, [:target_type, :action_at], :name => 'target_index'
    
    add_index :end_user_notes, [ :end_user_id, :created_at ], :name => 'user_index'
    
    drop_table :end_user_comments
    
    create_table :domain_log_sessions, :force => true do |t|
      t.integer :end_user_id
      t.datetime :created_at
      t.string :session_id
      t.integer :page_count
      t.datetime :last_entry_at
      t.integer :length
      t.string :ip_address
    end
    
    add_index :domain_log_sessions, [ :created_at ], :name => 'date_index'
    add_index :domain_log_sessions, [ :end_user_id, :created_at ], :name => 'user_index'
    
    add_column :domain_log_entries, :end_user_action_id, :integer
    add_column :domain_log_entries, :user_class_id, :integer
    remove_column :domain_log_entries, :paction_data
    remove_column :domain_log_entries, :user_model
    remove_column :domain_log_entries, :user_class
  end

  def self.down
    remove_column :domain_log_entries,:user_class_id
    remove_column :domain_log_entries,:end_user_action_id
    add_column :domain_log_entries, :paction_data, :string
    add_column :domain_log_entries, :user_model, :string
    add_column :domain_log_entries, :user_class, :string
    
    remove_index :end_user_notes, :name => 'user_index'
    
    create_table :end_user_comments do |t|
      
    end
  end
end
