class AddUniqueHostnameIndex < ActiveRecord::Migration
  def self.up
    add_index :servers, :hostname, :unique => true
  end

  def self.down
    remove_index :servers, :hostname
  end
end
