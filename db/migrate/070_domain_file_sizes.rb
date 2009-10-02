class DomainFileSizes < ActiveRecord::Migration
  def self.up
    create_table :domain_file_sizes, :force => true do |t|
      t.string :name
      t.string :size_name
      t.string :description
      t.text :operations
    end
    
    add_index :domain_file_sizes, [ :size_name ]
  end

  def self.down
    drop_table :domain_file_sizes
  end
end
