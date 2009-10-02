
class AddClientUserOptions < ActiveRecord::Migration

  def self.up
  
    add_column :client_users, :options, :text
  end  
  
  def self.down
    remove_column :client_users,:options
  end
end
