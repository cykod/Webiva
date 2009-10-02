class EndUserHandle < ActiveRecord::Migration
  def self.up
    add_column :end_users, :username, :string
  end

  def self.down
    remove_column :end_users, :username
  end
end
