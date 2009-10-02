
class EditHistory < ActiveRecord::Migration
  def self.up
  
    create_table :editor_changes,:force => true do |t|
      t.string :target_type
      t.integer :target_id
      t.text :edit_data
      t.timestamps
      t.integer :admin_user_id
      
    end
    
    add_index :editor_changes,[ :target_type,:target_id ], :name => 'edit_type_index'
    add_index :editor_changes,[ :created_at ], :name => 'created_index'
    add_index :editor_changes,[ :admin_user_id], :name => 'creator_index'

  end

  def self.down
    drop_table :editor_changes
  end
end
