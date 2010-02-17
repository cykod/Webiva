# Copyright (C) 2009 Pascal Rettig.

require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe Blog::BlogCategory do

  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes, :content_types

  before(:each) do
    @blog = Blog::BlogBlog.create :name => 'Test Blog', :content_filter => 'full_html'
    @category = @blog.blog_categories.build
  end

  it "category should not be valid" do
    @category.should_not be_valid
  end
  
  it "category should be createable with just a name and blog id" do
    @category.name = "Test Category"
    @category.should be_valid
  end

end
