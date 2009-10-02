
class EndUserLoginCookie < ActiveRecord::Migration
  def self.up
    create_table :end_user_cookies do |t|
      t.integer :end_user_id
      t.string :cookie
      t.datetime :valid_until
      t.timestamps
    end
    
    add_index :end_user_cookies, :end_user_id, :name => 'user_id'
    add_index :end_user_cookies, :cookie,  :name => 'cookie'
  end

  def self.down
    drop_table :end_user_cookies
  end
end
