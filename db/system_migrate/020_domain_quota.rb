class DomainQuota < ActiveRecord::Migration
  def self.up
    create_table :domain_databases, :force => true do |t|
      t.integer :client_id
      t.string :name
      t.text :options
      t.column :max_file_storage, :bigint
    end

    add_column :domains, :domain_database_id, :integer
    add_column :clients, :max_client_users, :integer
    add_column :clients, :max_file_storage, :bigint
    add_column :client_users, :domain_database_id, :integer
    add_column :client_users, :salt, :string

    add_index :client_users, :username, :unique => true
    add_index :clients, :name, :unique => true
  end

  def self.down
    drop_table :domain_databases

    remove_column :domains, :domain_database_id
    remove_column :clients, :max_client_users
    remove_column :clients, :max_file_storage
    remove_column :client_users, :domain_database_id
    remove_column :client_users, :salt

    remove_index :client_users, :username
    remove_index :clients, :name
  end
end
