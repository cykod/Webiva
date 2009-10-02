class AddDomainFileGeneration < ActiveRecord::Migration
  def self.up
    add_column :domain_files, :automatic, :boolean, :default => false
  end

  def self.down
    remove_column :domain_files, :automatic
  end
end
