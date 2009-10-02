# Copyright (C) 2009 Pascal Rettig.

class AddedBlogTarget < ActiveRecord::Migration
  def self.up
    add_column :blog_blogs, :is_user_blog, :boolean, :default => false
    add_column :blog_blogs, :target_type, :string
    add_column :blog_blogs, :target_id, :integer
    add_column :blog_blogs, :created_at, :datetime
    
    
  end

  def self.down
    remove_column :blog_blogs, :is_user_blog
    remove_column :blog_blogs, :target_type
    remove_column :blog_blogs, :target_id
    remove_column :blog_blogs, :created_at
  end

end
