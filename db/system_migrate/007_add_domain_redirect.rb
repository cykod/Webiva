class AddDomainRedirect < ActiveRecord::Migration
  def self.up
    add_column :domains, :domain_type, :string, :default => 'domain'
    add_column :domains, :redirect, :string
  end

  def self.down
    remove_column :domains, :domain_type
    remove_column :domains, :redirect
  end
end
