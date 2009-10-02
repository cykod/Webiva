class EndUserEmailContactUpdates < ActiveRecord::Migration
  def self.up
    add_column :end_users, :registered, :boolean, :default => false
    add_column :end_users, :user_level, :integer, :default => 1
    add_column :end_users, :source, :string
    add_column :end_users, :dob, :date
    add_column :end_users, :vip_number, :string
    add_column :end_users, :address_id, :integer
    add_column :end_users, :billing_address_id, :integer
    add_column :end_users, :work_address_id, :integer
    add_column :end_users, :created_at, :datetime
    add_column :end_users, :updated_at, :datetime
    
    create_table 'end_user_comments' do |t|
      t.column :end_user_id, :integer
      t.column :note_type, :string
      t.column :note, :text
    end
    
    create_table 'end_user_addresses' do |t|
      t.column  :end_user_id, :integer
      t.column  :address_name, :string
      t.column  :company, :string
      t.column  :phone, :string
      t.column  :fax, :string
      t.column  :address, :string
      t.column  :city, :string
      t.column  :state, :string
      t.column  :zip, :string
      t.column  :country, :string
    end
    
    add_index :end_users, :email, :name => 'email_index'
    
    # Make sure current users all have sensible defaults
    EndUser.find(:all).each do |usr|
      usr.update_attributes( :registered => true,
                             :user_level => 3,
                             :source => 'website',
                             :created_at => Time.now )
    end
  end

  def self.down
    remove_column :end_users, :registered
    remove_column :end_users, :user_level
    remove_column :end_users, :source
    remove_column :end_users, :dob
    remove_column :end_users, :vip_number
    remove_column :end_users, :address_id
    remove_column :end_users, :billing_address_id
    remove_column :end_users, :work_address_id
    remove_column :end_users, :created_at
    remove_column :end_users, :updated_at
    
    
    drop_table 'end_user_comments'
    drop_table 'end_user_addresses'
    
    remove_index :end_users, :name => 'email_index'
  end
end
