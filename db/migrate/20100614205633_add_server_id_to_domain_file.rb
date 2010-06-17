class AddServerIdToDomainFile < ActiveRecord::Migration
  def self.up
    add_column :domain_files, :server_id, :integer
    add_column :domain_files, :server_hash, :string
    add_column :domain_files, :mtime, :datetime
  end

  def self.down
    remove_column :domain_files, :server_id
    remove_column :domain_files, :server_hash
    remove_column :domain_files, :mtime
  end
end
