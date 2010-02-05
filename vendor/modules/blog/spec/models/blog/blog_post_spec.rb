# Copyright (C) 2009 Pascal Rettig.

require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"


describe Blog::BlogPost do

  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes

  before(:each) do
    @blog = Blog::BlogBlog.create(:name => 'Test Blog', :content_filter => 'full_html')
  end
  
  
  it "should create a content_node after create" do
    @blog.should be_valid
    rev = Blog::BlogPostRevision.new(:title => 'Test Post', :body => 'Testerama',:author => 'Anonymous')
    post = Blog::BlogPost.new(:blog_blog_id => @blog.id)
    
    post.should be_valid
    rev.should be_valid
    
    ContentNode.count.should == 0
    lambda {
      post.save_revision!(rev)
    }.should change { ContentNode.count  }.by(1)
  end


end
