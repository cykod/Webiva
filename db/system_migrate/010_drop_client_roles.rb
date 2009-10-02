class DropClientRoles < ActiveRecord::Migration
  def self.up
    drop_table :client_roles
    drop_table :client_permissions
  end

  def self.down
  end
end
