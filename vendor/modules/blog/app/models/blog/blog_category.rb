# Copyright (C) 2009 Pascal Rettig.

class Blog::BlogCategory < DomainModel

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => 'blog_blog_id'

  belongs_to :blog_blog

  has_many :blog_posts_categories, :class_name => 'Blog::BlogPostsCategory', :dependent => :delete_all




end
