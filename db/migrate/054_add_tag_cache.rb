class AddTagCache < ActiveRecord::Migration
  def self.up
    create_table :tag_cache do |t|
      t.column :end_user_id, :integer
      t.column :tags, :text
    end

    add_index :tag_cache, :end_user_id, :name => 'end_user'

    EndUser.find(:all).each do |usr|
      usr.update_tag_cache(usr.tag_names(true).join(","))
    end
  end

  def self.down
    drop_table :tag_cache
  end
end
