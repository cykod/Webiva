class AddDomainEmails < ActiveRecord::Migration
  def self.up
    create_table :domain_emails do |t|
      t.column :email, :string
      t.column :system_email, :boolean, :default => false
      t.column :email_type, :string, :default => 'mailbox'
      t.column :redirects, :text
      t.column :hashed_password, :string
      t.column :linked_account, :boolean, :default => false
      t.column :end_user_id, :integer
      t.column :virus_detection, :boolean, :default => false
      t.column :spam_detection_level, :integer, :default => 0
    end
    
  end

  def self.down
    drop_table :domain_emails
  end
end
