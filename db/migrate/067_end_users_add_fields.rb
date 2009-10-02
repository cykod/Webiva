class EndUsersAddFields < ActiveRecord::Migration
  def self.up
    add_column :end_users, :salutation, :string
    add_column :end_users, :middle_name, :string
  end

  def self.down
    remove_column :end_users, :salutation
    remove_column :end_users, :middle_name
  end
end
