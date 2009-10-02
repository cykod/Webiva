# Copyright (C) 2009 Pascal Rettig.


class Blog::BlogPostsCategory< DomainModel

  belongs_to :blog_post
  belongs_to :blog_category


end