class CreateServersTable < ActiveRecord::Migration
  def self.up
    create_table :servers, :force => true do |t|
      t.string :hostname
      t.integer :port, :default => 80
      t.integer :parent_server_id
      t.boolean :master_db
      t.boolean :domain_db
      t.boolean :slave_db
      t.boolean :web
      t.boolean :memcache
      t.boolean :starling
      t.boolean :workling
      t.boolean :cron
    end
  end

  def self.down
    drop_table :servers
  end
end
