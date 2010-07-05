class UserSegments < ActiveRecord::Migration
  def self.up
    create_table :user_segments, :force => true do |t|
      t.string :name
      t.text :description
      t.string :segment_type
      t.integer :market_segment_id
      t.string :status
      t.boolean :main_page
      t.datetime :last_ran_at
      t.integer :last_count
      t.text :fields
      t.text :segment_options
      t.text :segment_options_text
      t.string :order_by
      t.string :order_direction
      t.timestamps
    end

    create_table :user_segment_caches, :force => true do |t|
      t.integer :user_segment_id
      t.integer :position
      t.text :id_list, :limit => 16777215
      t.datetime :created_at
    end

    add_index :user_segment_caches, [:user_segment_id], :name => 'user_segment_cache_segment_idx'

    create_table :end_user_caches, :force => true, :options => "ENGINE=MyISAM" do |t|
      t.integer :end_user_id
      t.text :data
    end

    add_index :end_user_caches, [:end_user_id], :name => 'end_user_caches_idx', :unique => true
    execute "CREATE FULLTEXT INDEX end_user_caches_data_index ON end_user_caches (data)"

    execute "ALTER TABLE end_user_tags ADD COLUMN id INT PRIMARY KEY AUTO_INCREMENT"
  end

  def self.down
    drop_table :user_segments
    drop_table :user_segment_caches
    drop_table :end_user_caches

    execute "ALTER TABLE end_user_tags DROP COLUMN id"
  end
end
