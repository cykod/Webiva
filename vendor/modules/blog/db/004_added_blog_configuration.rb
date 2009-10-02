# Copyright (C) 2009 Pascal Rettig.

class AddedBlogConfiguration < ActiveRecord::Migration
  def self.up
    add_column :blog_blogs, :html_class, :string
  end

  def self.down
    remove_column :blog_blogs, :html_class
  end

end
