class AddDomainEmailEnabled < ActiveRecord::Migration
  def self.up
    add_column :domains, :email_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :domains, :email_enabled
  end
end
