
class DomainFileAdditionalTables < ActiveRecord::Migration
  def self.up
  
    add_column :domain_files, :created_at, :datetime
    add_column :domain_files, :stored_at, :datetime
    add_column :domain_files, :creator_id, :integer
    add_column :domain_files, :version_count, :integer, :default => 0
    add_column :domain_files, :mime_type, :string
    
    add_index :domain_files, :file_path, :name => 'file_path'
    add_index :domain_files, :prefix, :name =>'prefix'
  
    create_table :domain_file_instances do |t|
      t.integer :domain_file_id
      t.string :target_type, :size => 32
      t.integer :target_id
      t.string :column, :size => 64
    end
    
    add_index :domain_file_instances, :domain_file_id, :name => 'file_index'
    add_index :domain_file_instances, [:target_type,:target_id],:name => 'target_index'
    
    create_table :domain_file_versions do |t|
      t.integer :domain_file_id
      t.string :filename
      t.string :name
      t.string :file_type
      t.text :meta_info
      t.string :extension
      t.string :prefix
      t.integer :file_size
      t.integer :creator_id
      t.datetime :stored_at
      
      t.string :version_hash
      t.timestamps 
    end
    
  end

  def self.down 
    remove_column :domain_files, :created_at
    remove_column :domain_files, :stored_at
    remove_column :domain_files, :creator_id
    remove_column :domain_files, :version_count
    remove_column :domain_files, :mime_type
    drop_table :domain_file_instances
    drop_table :domain_file_versions
    
    remove_index :domain_files, :name => 'file_path'
    remove_index :domain_files, :name => 'prefix'
  end
end
