
class AddPingbackTable < ActiveRecord::Migration
  def self.up
    create_table :feedback_pingbacks do |t|
      t.column :source_uri, :string
      t.column :target_uri, :string
      t.column :content_node_id, :integer
      t.column :excerpt, :text
      t.column :title, :string
      t.column :posted_at,:datetime
      t.column :has_comment, :boolean, :default => 0
    end

    add_index :feedback_pingbacks, :source_uri, :name => 'feedback_pingbacks_source_index'

    add_column :comments, :source_id, :integer
    add_column :comments, :source_type, :string, :limit => 20

    add_index :comments, [ :source_type, :source_id ], :name => 'comments_source_index'

    create_table :feedback_outgoing_pingbacks do |t|
      t.column :content_node_id, :integer
      t.column :target_uri, :string
      t.column :accepted, :boolean
      t.column :sent_at, :datetime
      t.column :status_code, :integer
      t.column :status, :string
    end

    add_index :feedback_outgoing_pingbacks, [:content_node_id, :target_uri], :name => 'feedback_outgoing_pingbacks_content_index'
  end

  def self.down
    drop_table :feedback_pingbacks

    remove_column :comments, :source_id
    remove_column :comments, :source_type

    drop_table :feedback_outgoing_pingbacks
  end
end
