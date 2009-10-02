# Copyright (C) 2009 Pascal Rettig.

class MoreAddedBlogFeatures < ActiveRecord::Migration
  def self.up
    add_column :blog_post_revisions, :embedded_media, :text
  end

  def self.down
    remove_column :blog_post_revisions, :embedded_media
  end

end
