class AddTagIndexes < ActiveRecord::Migration
  def self.up
    add_index :end_user_tags, [ :end_user_id, :tag_id ], :name => 'euid_tagid'
    add_index :end_user_tags, [ :tag_id, :end_user_id ], :name => 'tagid_euid'
  end

  def self.down
  end
end
