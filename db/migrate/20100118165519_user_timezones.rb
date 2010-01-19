class UserTimezones < ActiveRecord::Migration
  def self.up
    add_column :end_users, :time_zone, :string
  end

  def self.down
    remove_column :end_users, :time_zone
  end
end
