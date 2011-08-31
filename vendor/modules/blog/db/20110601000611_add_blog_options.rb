class AddBlogOptions < ActiveRecord::Migration
  def self.up
    add_column :blog_blogs, :options_data, :text
    add_column :blog_categories, :permalink, :string
    add_column :blog_categories, :long_title, :string
  end

  def self.down
    remove_column :blog_blogs, :options_data
    remove_column :blog_categories, :permalink
    remove_column :blog_categories, :long_title
  end
end
