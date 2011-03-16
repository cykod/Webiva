class EndUserActions < ActiveRecord::Migration
  def self.up
    create_table :end_user_actions do |t|
      t.integer :end_user_id
      t.integer :level, :default => 1 #0-admin, #1 - data, #2-login/access,  #3-action, #4 - information,  #5-conversion
      t.datetime :action_at
      t.datetime :created_at    
      t.string :target_type
      t.integer :target_id
      t.string :controller, :limit => 64
      t.string :action, :limit => 128
      t.string :path
      t.text :data
    end
    
    # register_action '/editor/auth/login', :description => 'Logged in'
    # register_action '/shop/processor/order', :description => 'Purchase', :controller => '/shop/manage', :action => 'view', :level => 4, :path => :target
    
    # myself.action("/editor/auth/login')
    # myself.action("/shop/processor/order',:target => @order)
    
    add_index :end_user_actions, [:end_user_id, :created_at], :name => 'user_date_index'
    add_index :end_user_actions, [:controller, :action, :created_at], :name => 'action index'
    
    create_table :end_user_notes do |t|
      t.integer :end_user_id    
      t.integer :admin_user_id
      t.text :note
      t.datetime :created_at
      t.datetime :updated_at
    end
    
    add_index :end_user_notes, [:end_user_id, :created_at], :name => 'user_date_index'
    
    create_table :end_user_content_entries do |t|
      t.integer :end_user_id
      t.integer :content_model_id
      t.integer :entry_id
      t.timestamps
    end
    
    add_index :end_user_content_entries, :end_user_id, :name => 'user_index'
    add_index :end_user_content_entries, [ :content_model_id, :entry_id ], :name => 'content_index'
    
    add_column :end_users, :membership_id, :string
  end

  def self.down
      drop_table :end_user_actions
      drop_table :end_user_notes
      drop_table :end_user_content_entries
      
      remove_column :end_users, :membership_id
  end
end
