
class DomainFileRelativePath < ActiveRecord::Migration
  def self.up
    add_column :domain_files, :prefix, :string
    add_column :domain_files, :extension, :string
    add_column :domain_files, :file_size, :integer
    
    execute "UPDATE domain_files SET prefix=id WHERE 1"
  end

  def self.down
    remove_column :domain_files, :extension
    remove_column :domain_files, :prefix
    remove_column :domain_files, :file_size
  end
end
