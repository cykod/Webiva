class AddUserSubscriptions < ActiveRecord::Migration
  def self.up
    # Moved most to Mailing Module
    
    create_table :market_segments do |t|
      t.column :market_campaign_id, :integer
      t.column :name, :string
      t.column :description, :text
      t.column :segment_type, :string
      t.column :user_subscription_id, :integer
      t.column :options, :text
      t.column :created_at, :datetime
      t.column :last_sent_at, :datetime
    end
    
    
   create_table :user_subscriptions do |t|
      t.column :name, :string
      t.column :description, :text
      t.column :require_registered_user, :boolean
      t.column :registration_email, :boolean, :default => true
      t.column :registration_template_id, :integer
      t.column :double_opt_in, :boolean, :default => false
      t.column :double_opt_in_template_id, :integer
    end
  
    create_table :user_subscription_entries do |t|
      t.column :user_subscription_id, :integer
      t.column :subscription_type, :string # Website, Manual
      t.column :subscribed_at, :datetime
      t.column :subscribed_ip, :string
      t.column :email, :string
      t.column :end_user_id, :integer
      t.column :verified, :boolean, :default => false
      t.column :verified_at, :datetime
      t.column :verified_ip, :string
      t.column :verification, :string
      t.column :subscribed, :boolean, :default => true
    end
    
    add_index :user_subscription_entries, :user_subscription_id, :name=> 'user_subscription_id'
        
  end

  def self.down
    remove_column :user_subscription_entries,:subscribed
    
  end
end
