# Copyright (C) 2009 Pascal Rettig.

class AddedBlogFeatures < ActiveRecord::Migration
  def self.up
    add_column :blog_blogs, :site_template_id, :integer
    
    add_column :blog_post_revisions, :media_file_id, :integer
  
  end

  def self.down
    remove_column :blog_blogs, :site_template_id
    
    remove_column :blog_post_revisions, :media_file_id
  end

end
