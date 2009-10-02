class AddEmailMailboxes < ActiveRecord::Migration
  def self.up
  
    create_table :email_mailboxes do |t|
      t.column :domain_id, :integer
      t.column :domain_email_id, :integer
      t.column :mailbox_type, :string, :default => 'normal'
      t.column :user, :string
      t.column :email, :string
      t.column :password, :string
      t.column :touched, :boolean, :default => false
    end
    
    add_index :email_mailboxes, :email, :name => 'email_addr'
    
    create_table :email_aliases do |t|
      t.column :domain_id, :integer
      t.column :domain_email_id, :integer
      t.column :alias, :string
      t.column :destination, :string
      t.column :touched, :boolean, :default => false
    end
    
    add_index :email_aliases, :alias, :name => 'alias'
    add_index :email_aliases, :destination, :name => 'destination'
    
    create_table :email_transports do |t|
      t.column :domain_id, :integer
      t.column :domain_email_id, :integer
      t.column :user, :string
      t.column :transport, :string
      t.column :touched, :boolean, :default => false
    end 
    
    add_index :email_transports, :user, :name => 'user_email'
  end

  def self.down
    drop_table  :email_mailboxes
    drop_table  :email_aliases
    drop_table :email_transports
    
  end
end
