class DomainsAddSsl < ActiveRecord::Migration
  def self.up
    add_column :domains, :ssl_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :domains, :ssl_enabled
  end
end
