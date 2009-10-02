
class EndUserImage2 < ActiveRecord::Migration
  def self.up
      
    add_column :end_users, :second_image_id,:integer
  end

  def self.down
    remove_column :end_users, :second_image_id
  end
end
