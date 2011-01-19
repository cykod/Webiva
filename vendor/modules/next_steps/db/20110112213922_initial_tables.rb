class InitialTables < ActiveRecord::Migration
  def self.up
    create_table :next_steps_steps, :force => true do |t|
      t.string :action_text, :limit => 8, :null => true
      t.string :description_text, :page, :null => true
      t.integer :document_id
      t.timestamps
    end
    add_index :next_steps_steps, :id
  end

  def self.down
    remove_index :next_steps_steps, :id
    drop_table :next_steps_steps
  end
end