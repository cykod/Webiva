class AddSpecialToDomainFile < ActiveRecord::Migration
  def self.up
    add_column :domain_files, :special, :string, :limit => 10, :default => ''
  end

  def self.down
    remove_column :domain_files, :special
  end
end
