class AddEditorLogin < ActiveRecord::Migration
  def self.up
  
    create_table :editor_logins do |t|
      t.column :email, :string
      t.column :domain_id, :integer
      t.column :end_user_id, :integer
      t.column :hashed_password, :string
      t.column :login_hash, :string
    end
    add_index :editor_logins, :email, :name => 'email'
    add_index :editor_logins, :login_hash, :name => 'login_hash'
    
  end

  def self.down
    drop_table :editor_logins
    
  end
end
