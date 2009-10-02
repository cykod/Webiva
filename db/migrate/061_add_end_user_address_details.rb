class AddEndUserAddressDetails < ActiveRecord::Migration
  def self.up
    add_column :end_user_addresses, :address_2, :string
    add_column :end_user_addresses, :first_name, :string
    add_column :end_user_addresses, :last_name, :string
  end

  def self.down
    remove_column :end_user_addresses, :address_2
    remove_column :end_user_addresses, :first_name
    remove_column :end_user_addresses, :last_name
  end
end
