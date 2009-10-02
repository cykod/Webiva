class CreateCompontentSchemas < ActiveRecord::Migration
  def self.up
    create_table :component_schemas, :id => false do |t|
      t.column :version, :integer, :default => 0
      t.column :component, :string
    end
    
    
  end

  def self.down
    drop_table :component_schemas
  end
end
