
class EndUserCell < ActiveRecord::Migration
  def self.up
      
    add_column :end_users, :cell_phone, :string
  end

  def self.down
    remove_column :end_users, :cell_phone
  end
end
