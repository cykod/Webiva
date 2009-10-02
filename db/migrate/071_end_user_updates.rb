class EndUserUpdates < ActiveRecord::Migration
  def self.up
    add_column :end_users, :lead_source, :string
    add_column :end_users, :registered_at, :datetime
  end

  def self.down
    remove_column :end_users, :lead_source
    remove_column :end_users, :registered_at
  end
end
