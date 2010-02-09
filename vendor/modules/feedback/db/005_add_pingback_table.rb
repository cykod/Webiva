
class AddPingbackTable < ActiveRecord::Migration
  def self.up
    create_table :feedback_pingbacks do |t|
      t.column :source_uri, :string
      t.column :target_uri, :string
      t.column :content_node_id, :integer
      t.column :comment_id, :integer
      t.column :excerpt, :text
      t.column :title, :string
      t.column :posted_at,:datetime
      t.column :accepted, :boolean, :default => 0
      t.column :accepted_at,:datetime
    end

    add_index :feedback_pingbacks, :source_uri, :name => 'feedback_pingbacks_source_index'
  end

  def self.down
    drop_table :feedback_pingbacks
  end
end
