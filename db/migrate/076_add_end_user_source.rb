class AddEndUserSource < ActiveRecord::Migration
  def self.up
    add_column :end_users, :source_user_id, :integer
  end

  def self.down
    remove_column :end_users, :source_user_id
  end
end
