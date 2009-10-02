class AddEndUserPicture < ActiveRecord::Migration
  def self.up
    add_column :end_users, :domain_file_id, :integer
  end

  def self.down
    remove_column :end_users, :domain_file_id
  end
end
