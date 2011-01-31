class InitialTables < ActiveRecord::Migration
  def self.up
    create_table :looking_for_locations, :force => true do |t|
      t.string :action_text, :limit => 8, :null => true
      t.string :description_text, :page, :null => true
      t.integer :document_id
      t.timestamps
    end
    add_index :looking_for_locations, :id
  end

  def self.down
    remove_index :looking_for_locations, :id
    drop_table :looking_for_locations
  end
end