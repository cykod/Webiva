require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../feedback_test_helper'

require 'xmlrpc/client'

describe Feedback::PingbackController do

  include FeedbackTestHelper

  class XmlrpcRequest
    attr_accessor :params, :methodName

    def initialize
      @params = []
    end

    def add_param(value)
      @params << value
    end

    def to_xml
      xml = "<?xml version=\"1.0\" ?><methodCall><methodName>#{@methodName}</methodName><params>"
      @params.each do |value|
	xml << "<param><value><string>#{value}</string></value></param>"
      end
      xml << "</params></methodCall>"
      xml
    end
  end

  reset_domain_tables :feedback_pingbacks, :comments, :content_nodes, :content_node_values, :blog_posts

  before(:each) do
    mock_editor
    @post = Blog::BlogPost.create
    @link = '/test-post'
    @type = ContentType.create :component => 'blog', :container_type => 'Blog::BlogBlog', :container_id => 1, :content_type => 'Blog::BlogPost', :content_name => 'Mock Blog', :title_field => 'title'
    @node = @type.content_nodes.create :node => @post
    @node_value = @node.content_node_values.create :content_type_id => @type.id, :link => @link
    @source_uri = 'http://myexternal.test.site.com/test-post'
    @target_uri = Configuration.domain_link @link

    @rpc_request = XmlrpcRequest.new
    @rpc_request.methodName = 'pingback.ping'
    @rpc_request.add_param @source_uri
    @rpc_request.add_param @target_uri
  end


  it "should add a pingback to the post" do
    FeedbackPingback.should_receive(:retrieve_source_content).and_return("<html><head><title>Test Title</title></head>This is a great <a href='#{@target_uri}'>post</a>.</html>")

    assert_difference 'FeedbackPingback.count', 1 do
      request.env['content_type'] = 'application/xml'
      request.env['RAW_POST_DATA'] =  @rpc_request.to_xml
      post :index
    end

    response.body.should include(@target_uri)
    response.body.should include(@source_uri)
    response.body.should_not include('fault')
  end

  it "should not add a pingback if the target is not in the source" do
    FeedbackPingback.should_receive(:retrieve_source_content).and_return("<html><head><title>Test Title</title></head><body>This is a great <a href='/test-post'>post</a>.</body></html>")

    assert_difference 'FeedbackPingback.count', 0 do
      request.env['content_type'] = 'application/xml'
      request.env['RAW_POST_DATA'] =  @rpc_request.to_xml
      post :index
    end

    response.body.should include('faultCode')
    response.body.should include('17')
  end

  it "should not add a pingback if the source url is not found" do
    @rpc_request = XmlrpcRequest.new
    @rpc_request.methodName = 'pingback.ping'
    @rpc_request.add_param 'http://fake.test.dev/post'
    @rpc_request.add_param @target_uri

    assert_difference 'FeedbackPingback.count', 0 do
      request.env['content_type'] = 'application/xml'
      request.env['RAW_POST_DATA'] =  @rpc_request.to_xml
      post :index
    end

    response.body.should include('faultCode')
    response.body.should include('16')
  end
end
