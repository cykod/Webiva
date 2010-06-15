class AddServerIdToDomainFile < ActiveRecord::Migration
  def self.up
    add_column :domain_files, :server_id, :integer
    add_column :domain_files, :server_hash, :string
  end

  def self.down
    remove_column :domain_files, :server_id
    remove_column :domain_files, :server_hash
  end
end
