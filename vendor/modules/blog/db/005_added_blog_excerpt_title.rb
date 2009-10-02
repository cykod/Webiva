# Copyright (C) 2009 Pascal Rettig.

class AddedBlogExcerptTitle < ActiveRecord::Migration
  def self.up
    add_column :blog_post_revisions, :preview_title, :string
  end

  def self.down
    remove_column :blog_post_revisions, :preview_title
  end

end
