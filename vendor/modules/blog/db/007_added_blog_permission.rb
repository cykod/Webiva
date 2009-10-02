# Copyright (C) 2009 Pascal Rettig.

class AddedBlogPermission < ActiveRecord::Migration
  def self.up
    add_column :blog_blogs, :edit_permission, :boolean, :default => false
  end

  def self.down
    remove_column :blog_blogs, :edit_permission
  end

end
