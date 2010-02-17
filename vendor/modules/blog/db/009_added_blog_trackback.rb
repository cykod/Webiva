
class AddedBlogTrackback < ActiveRecord::Migration
  def self.up
    add_column :blog_blogs, :trackback, :boolean, :default => true
  end

  def self.down
    remove_column :blog_blogs, :trackback
  end
end
