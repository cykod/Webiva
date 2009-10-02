class AddEmailFriendsUrl < ActiveRecord::Migration
  def self.up
    add_column :email_friends, :site_url, :string
    add_index :email_friends, [ :site_url, :sent_at ], :name => 'url_index'
  end

  def self.down
    remove_column :email_friends, :site_url
  end
end
