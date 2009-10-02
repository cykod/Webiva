class AddEndUserReferrer < ActiveRecord::Migration
  def self.up
    add_column :end_users, :referrer, :string
  end

  def self.down
    remove_column :end_users, :referrer
  end
end
