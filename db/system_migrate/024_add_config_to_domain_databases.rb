
class AddConfigToDomainDatabases < ActiveRecord::Migration
  def self.up
    add_column :domain_databases, :config, :text
  end

  def self.down
    remove_column :domain_databases, :config
  end
end
