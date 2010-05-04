# Copyright (C) 2009 Pascal Rettig.

require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"


describe Blog::BlogPost do

  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes

  before(:each) do
    @blog = Blog::BlogBlog.create(:name => 'Test Blog', :content_filter => 'full_html')
  end
  
  
  it "should create a content_node after create" do
    @blog.should be_valid
    post = Blog::BlogPost.new(:blog_blog_id => @blog.id, :title => 'Test Post', :body => 'Testerama',:author => 'Anonymous')
    
    post.should be_valid
    
    ContentNode.count.should == 0
    lambda {
      post.save
    }.should change { ContentNode.count  }.by(1)
    Blog::BlogPostRevision.count.should == 1
  end

  it "should be able to create and resave a post" do
    @post = @blog.blog_posts.build(:title => 'Tester', :body => 'Body!')
    
    assert_difference "Blog::BlogPost.count", 1 do
      @post.save
    end

    Blog::BlogPostRevision.count.should == 1
    @revision = Blog::BlogPostRevision.find(:last)

    @revision.title.should == 'Tester'
    @post.reload
    @post.title = 'Tester Title 2'
    @post.save

    Blog::BlogPostRevision.count.should == 2

    @revision.reload
    @revision.title.should == 'Tester'
    Blog::BlogPostRevision.find(:last).title.should == 'Tester Title 2'
  end


end
