
class DomainsTableUpdate < ActiveRecord::Migration
  def self.up
    add_column :domain_databases, :inactive, :boolean, :default => false
    add_column :clients, :inactive, :boolean, :default => false
    add_column :clients, :database_limit, :integer, :default => 10
  end

  def self.down
    remove_column :domain_databases, :inactive
    remove_column :clients, :inactive
    remove_column :database_limit, :default => 10
  end
end
