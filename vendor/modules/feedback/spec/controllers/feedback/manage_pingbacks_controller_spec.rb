require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../feedback_test_helper'

describe Feedback::ManagePingbacksController do

  include FeedbackTestHelper

  reset_domain_tables :feedback_pingbacks, :comments, :content_nodes, :content_node_values, :blog_posts, :blog_blogs, :blog_post_revisions

  before(:each) do
    mock_editor
    blog = Blog::BlogBlog.create(:name=>'Blog',:content_filter => 'full_html' )
    @post = blog.blog_posts.create(:title => 'Test Title', :body => 'Test Body')
    @link = '/test-post'
    @type = ContentType.create :component => 'blog', :container_type => 'Blog::BlogBlog', :container_id => 1, :content_type => 'Blog::BlogPost', :content_name => 'Mock Blog', :title_field => 'title'
    @node = @type.content_nodes.create :node => @post
    @node_value = @node.content_node_values.create :content_type_id => @type.id, :link => @link
    @source_uri = 'http://myexternal.test.site.com/test-post'
    @target_uri = Configuration.domain_link @link
    @pingback = FeedbackPingback.create :source_uri => @source_uri, :target_uri => @target_uri, :content_node_id => @node.id, :posted_at => Time.now, :title => 'Test Pingback', :excerpt => 'Test Excerpt'
  end

  it "should render the index page" do 
    get 'index'
  end

  it "should handle table list" do 
      # Test all the permutations of an active table
    controller.should handle_active_table(:pingbacks_table) do |args|
      post 'pingbacks_table', args
    end
  end

  it "should be able to delete a pingbacks from feedback_pingbacks table" do
    assert_difference 'FeedbackPingback.count', -1 do
      post 'pingbacks_table', :table_action => 'delete', :pingback => {@pingback.id => @pingback.id}
    end
  end

  it "should be able to create a comment from feedback_pingbacks table" do
    assert_difference 'Comment.count', 1 do
      post 'pingbacks_table', :table_action => 'create', :pingback => {@pingback.id => @pingback.id}
    end

    comment = Comment.find(:last)
    comment.name.should == @pingback.title
    comment.source.should == @pingback
  end

  it "should be able to remove a comment from feedback_pingbacks table" do
    assert_difference 'Comment.count', 1 do
      @pingback.create_comment(@myself)
    end

    assert_difference 'Comment.count', -1 do
      post 'pingbacks_table', :table_action => 'remove', :pingback => {@pingback.id => @pingback.id}
    end
  end
end
