class AddServerIdToDomainFile < ActiveRecord::Migration
  def self.up
    add_column :domain_files, :server_id, :integer
    add_column :domain_files, :server_hash, :string
    add_column :domain_files, :mtime, :datetime

    add_column :domain_file_versions, :server_id, :integer
  end

  def self.down
    remove_column :domain_files, :server_id
    remove_column :domain_files, :server_hash
    remove_column :domain_files, :mtime

    remove_column :domain_file_versions, :server_id
  end
end
