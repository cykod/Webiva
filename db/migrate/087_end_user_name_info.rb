
class EndUserNameInfo < ActiveRecord::Migration
  def self.up
      
    add_column :end_users, :introduction, :string
    add_column :end_users, :suffix,:string
    add_column :end_users, :full_name,:string
  end

  def self.down
    remove_column :end_users, :introduction
    remove_column :end_users, :suffix
    remove_column :end_users, :full_name
  end
end
