class DomainFileAddAccess < ActiveRecord::Migration
  def self.up
    add_column :domain_files, :private, :boolean, :default => false
  end

  def self.down
    remove_column :domain_files, :private
  end
end
