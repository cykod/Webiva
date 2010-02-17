class AddContentTags < ActiveRecord::Migration
  def self.up
    create_table :content_tags do |t|
      t.string :name, :limit => 128
      t.string :content_type, :limit => 128
    end
    
    add_index  :content_tags, [ :content_type, :name ], :name => 'content_tags'
    
    create_table :content_tag_tags do |t|
      t.integer :content_tag_id
      t.string :content_type
      t.integer :content_id
    end
    
    add_index :content_tag_tags, :content_tag_id, :name => 'content_tag_id'
    add_index :content_tag_tags, [ :content_type, :content_id ], :name => 'content_type'
  end

  def self.down
    drop_table :content_tags
    drop_table :content_tag_tags
  end
end
