
class AddedBlogContentFilters < ActiveRecord::Migration
  def self.up
    add_column :blog_blogs, :content_filter, :string
    add_column :blog_blogs, :folder_id, :integer

    execute "UPDATE blog_blogs SET content_filter = 'full_html' WHERE 1"
  end

  def self.down
    remove_column :blog_blogs, :content_filter
    remove_column :blog_blogs, :folder_id
  end
end
