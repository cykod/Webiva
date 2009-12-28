class AccessTokenTarget < ActiveRecord::Migration
  def self.up
    add_column :end_user_tokens, :valid_at, :datetime
    add_column :end_user_tokens,:target_type,:string
    add_column :end_user_tokens, :target_id, :integer

    add_column :end_users, :salt, :string
    add_column :end_users, :activated, :boolean, :default => true
    add_column :end_users, :activation_string, :string

    

    add_column :access_tokens, :role_cache, :text
    add_column :user_classes, :role_cache, :text
    
  end

  def self.down
    remove_column :end_user_tokens, :valid_at
    remove_column :end_user_tokens, :target_type
    remove_column :end_user_tokens, :target_id

    remove_column :end_users, :salt
    remove_column :end_users, :activated
    remove_column :end_users, :activation_string

    remove_column :access_tokens, :role_cache
    remove_column :user_classes, :role_cache
  end


end
