class DomainQuota < ActiveRecord::Migration
  def self.up
    create_table :domain_databases, :force => true do |t|
      t.integer :client_id
      t.string :name
      t.text :options
      t.integer :max_client_users
      t.column :available_file_storage, :bigint
    end

    add_column :domains, :domain_database_id, :integer
    add_column :clients, :max_client_users, :integer
    add_column :clients, :available_file_storage, :bigint
  end

  def self.down
    drop_table :domain_databases

    remove_column :domains, :domain_database_id
    remove_column :clients, :max_client_users
    remove_column :clients, :available_file_storage
  end
end
