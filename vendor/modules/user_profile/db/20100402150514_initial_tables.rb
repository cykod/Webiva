class InitialTables < ActiveRecord::Migration
  def self.up
    create_table :user_profile_types do |t|
      t.string :name
      t.integer :content_model_id
      t.integer :content_model_field_id
    end
   
    add_index :user_profile_types,  :name, :name => 'user_profile_type_name'
   
    create_table :user_profile_type_user_classes do |t|
      t.integer :user_class_id
      t.integer :user_profile_type_id
    end
   
    
    create_table :user_profile_entries do |t|
      t.integer :user_profile_type_id
      t.integer :end_user_id
      t.string :url
      t.boolean :published, :default => true
      t.boolean :protected, :default => false
      t.integer :content_model_id
    end
  end

  def self.down
    drop_table :user_profile_types
    drop_table :user_profile_type_user_classes
    drop_table :user_profile_entries
  end
end
