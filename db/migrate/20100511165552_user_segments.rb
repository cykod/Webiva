class UserSegments < ActiveRecord::Migration
  def self.up
    create_table :user_segments, :force => true do |t|
      t.string :name
      t.text :description
      t.string :type
      t.boolean :main_page
      t.datetime :last_ran_at
      t.integer :last_count
      t.text :fields
      t.text :segment_options
      t.text :segment_options_text
      t.string :order_by
      t.timestamps
    end

    create_table :user_segment_caches, :force => true do |t|
      t.integer :user_segment_id
      t.text :id_list
      t.datetime :created_at
    end

    add_index :user_segment_caches, [:user_segment_id], :name => 'user_segment_cache_segment_idx'

    create_table :user_segment_analytics, :force => true do |t|
      t.integer :user_segment_id
      t.text :fields
      t.text :results
      t.datetime :start_date
      t.datetime :end_date
      t.string :step
      t.timestamps
    end

    add_index :user_segment_analytics, [:user_segment_id], :name => 'user_segment_analytics_segment_idx'
  end

  def self.down
    drop_table :user_segments
    drop_table :user_segment_caches
    drop_table :user_segment_analytics
  end
end
