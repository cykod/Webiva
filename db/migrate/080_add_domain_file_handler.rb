class AddDomainFileHandler < ActiveRecord::Migration
  def self.up
    add_column :domain_files, :processor, :string, :default => 'local'
    add_column :domain_files, :processor_status, :string, :default => 'ok'
  end

  def self.down
    remove_column :domain_files, :processor
    remove_column :domain_files, :processor_status
  end
end
