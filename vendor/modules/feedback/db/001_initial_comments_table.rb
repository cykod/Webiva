# Copyright (C) 2009 Pascal Rettig.

class InitialCommentsTable < ActiveRecord::Migration
  def self.up

    create_table :comments do |t|
      t.column :target_type, :string, :limit => 20
      t.column :target_id, :integer
      t.column :end_user_id, :integer
      t.column :posted_at,:datetime
      t.column :posted_ip, :string
      t.column :comment, :text
      t.column :rating, :integer, :default => 0
      t.column :rated_at, :datetime
      t.column :rated_by_user_id, :integer
      t.column :name, :string
    end

    add_index :comments, [ :target_type, :target_id, :posted_at ], :name => 'target_index'
    add_index :comments, :posted_at, :name => 'posted_at_index'
    add_index :comments, [ :end_user_id, :posted_at ], :name => 'end_user_index'
  end

  def self.down
    drop_table :comments
  end
end
