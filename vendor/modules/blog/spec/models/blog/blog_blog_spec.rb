# Copyright (C) 2009 Pascal Rettig.

require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"


describe Blog::BlogBlog do


  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes, :content_types, :blog_targets,:end_users

  before(:each) do
    @blog = Blog::BlogBlog.new
  end
  

  it "blog should not be valid" do
    @blog.should_not be_valid
  end
  
  it "blog should be createable with just a name and filter" do
    @blog.name = "Test Blog"
    @blog.content_filter = 'full_html'
    @blog.should be_valid
  end
  
  it "blog should create a content type if its not a user blog" do
    @blog.name = "Test Blog"
    @blog.content_filter = 'full_html'
    lambda {
      @blog.save
    }.should change { ContentType.count  }.by(1)
    
    ct = ContentType.find(:last)
    
    ct.content_name.should == "Test Blog"
    ct.container_type.should == 'Blog::BlogBlog'
    ct.container_id.should == @blog.id
    ct.content_type.should == "Blog::BlogPost"
    ct.title_field.should == 'title'
  end
  
  it "should change the content_filter to markdown_safe for user blogs" do
    @blog.name = 'Test Blog'
    @blog.target = EndUser.push_target('tester@webiva.org')
    @blog.is_user_blog = true
    @blog.save.should be_true
    @blog.content_filter.should == 'safe_html'
  end

  it "should create a blog target if it's a user blog" do
    assert_difference "Blog::BlogTarget.count", 1 do 
      @blog.is_user_blog = true
      @blog.target = EndUser.push_target('tester@webiva.org')
      @blog.name = "User Blog"
      @blog.save.should be_true
    end
    ContentType.count.should == 1

  end

end
