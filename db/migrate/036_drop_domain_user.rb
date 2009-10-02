class DropDomainUser < ActiveRecord::Migration
  def self.up
    drop_table :domain_users
  end

  def self.down
    raise IrreversibleMigrationException
  end
end
