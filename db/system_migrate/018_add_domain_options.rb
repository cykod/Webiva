class AddDomainOptions < ActiveRecord::Migration
  def self.up
    add_column :domains, :www_prefix, :boolean, :default => true
    add_column :domains, :primary, :boolean,:default => false
    add_column :domains, :site_version_id,:integer, :default => 1
    add_column :domains, :active, :boolean, :default => 1
    add_column :domains, :restricted, :boolean, :default => 0
    add_column :domains, :inactive_message, :text
  end

  def self.down
    remove_column :domains, :www_prefix
    remove_column :domains, :primary
    remove_column :domains, :site_version_id
    remove_column :domains, :active
    remove_column :domains, :restricted
    remove_column :domains, :inactive_message
  end
end
