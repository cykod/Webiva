class AddEndUserClientUserId < ActiveRecord::Migration
  def self.up
    add_column :end_users, :shipping_address_id, :integer
    add_column :end_users, :client_user_id, :integer
    
  end

  def self.down
    remove_column :end_users, :shipping_address_id
    remove_column :end_users, :client_user_id
  end
end
