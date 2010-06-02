class DomainQuota < ActiveRecord::Migration
  def self.up
    create_table :domain_databases, :force => true do |t|
      t.string :name
      t.text :options
      t.integer :max_client_users
      t.column :available_file_storage, :bigint
    end

    add_column :domains, :domain_database_id, :integer
  end

  def self.down
    drop_table :domain_databases

    remove_column :domains, :domain_database_id
  end
end
