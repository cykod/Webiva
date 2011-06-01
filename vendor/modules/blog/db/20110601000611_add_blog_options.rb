class AddBlogOptions < ActiveRecord::Migration
  def self.up
    add_column :blog_blogs, :options_data, :text
    add_column :blog_categories, :permalink, :string
  end

  def self.down
    remove_column :blog_blogs, :options_data
    remove_column :blog_categories, :permalink
  end
end
