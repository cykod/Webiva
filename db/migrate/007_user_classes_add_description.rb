class UserClassesAddDescription < ActiveRecord::Migration
  def self.up
    add_column :user_classes, :description, :string
  end

  def self.down
    remove_column :user_classes, :description, :string
  end
end
