class AddDomainFileStore < ActiveRecord::Migration
  def self.up
    add_column :domains, :file_store, :integer
  end

  def self.down
    remove_column :domains, :file_store
  end
end
