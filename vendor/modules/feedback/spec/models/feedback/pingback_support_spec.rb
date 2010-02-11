require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe Feedback::PingbackSupport do

  reset_domain_tables :feedback_pingbacks, :comments, :content_nodes, :content_node_values, :blog_posts

  class Pinger
    attr_accessor :id, :html
    include Feedback::PingbackSupport
  end

  before(:each) do
    @post = Blog::BlogPost.create
    @link = '/test-post'
    @type = ContentType.create :component => 'blog', :container_type => 'Blog::BlogBlog', :container_id => 1, :content_type => 'Blog::BlogPost', :content_name => 'Mock Blog', :title_field => 'title'
    @node = @type.content_nodes.create :node => @post
    @node_value = @node.content_node_values.create :content_type_id => @type.id, :link => @link
    @source_uri = 'http://myexternal.test.site.com/test-post'
    @target_uri = Configuration.domain_link @link
    @pinger = Pinger.new
  end

  it "should do nothing if html of field are not specified" do
    ContentNode.should_receive(:find_by_node_type_and_node_id).exactly(0).times
    @pinger.send_pingbacks
  end

  it "should add pingbacks" do
    @node.should_receive(:link).any_number_of_times.and_return(@link)
    ContentNode.should_receive(:find_by_node_type_and_node_id).with(@pinger.class.to_s, anything()).and_return(@node)
    FeedbackOutgoingPingback.should_receive(:add_pingback).with(@node, 'http://test.dev/test')
    @pinger.send_pingbacks :html => '<html><body><p>Fake <a href="http://test.dev/test">link</a></p></body></html>'
  end
end
