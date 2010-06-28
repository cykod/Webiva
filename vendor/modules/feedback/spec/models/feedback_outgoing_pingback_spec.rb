require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

describe FeedbackOutgoingPingback do

  reset_domain_tables :feedback_outgoing_pingbacks, :comments, :content_nodes, :content_node_values, :blog_posts

  it "should require content and target" do
    @comment = FeedbackOutgoingPingback.new
    @comment.valid?
    @comment.should have(1).errors_on(:content_node_id)
    @comment.should have(1).errors_on(:target_uri)
  end

  describe "processing outgoing pingbacks" do
    before(:each) do
      @blog = Blog::BlogBlog.create(:name => 'Tester')
      @post = Blog::BlogPost.create(:blog_blog_id => @blog.id)
      @link = '/test-post'
      @type = ContentType.create :component => 'blog', :container_type => 'Blog::BlogBlog', :container_id => 1, :content_type => 'Blog::BlogPost', :content_name => 'Mock Blog', :title_field => 'title'
      @node = @type.content_nodes.create :node => @post
      @node_value = @node.content_node_values.create :content_type_id => @type.id, :link => @link
      @source_uri = Configuration.domain_link @link
      @target_uri = 'http://myexternal.test.site.com/test-post'
    end

    def fake_client(ok, param)
      @client = mock 
      @client.should_receive(:send_pingback).once.and_return([ok, param])
      FeedbackPingbackClient.should_receive(:new).and_return(@client)
    end

    def fake_fault(faultCode, faultString)
      mock :faultCode => faultCode, :faultString => faultString
    end

    it "should detect if the target is on the same host" do
      same_host_target = Configuration.domain_link '/same-host'
      FeedbackOutgoingPingback.add_pingback(@node, same_host_target).should be_nil
    end

    it "should detect if the target is not a full url" do
      target = '/same-host'
      FeedbackOutgoingPingback.add_pingback(@node, target).should be_nil
    end

    it "should save the outgoing pingback" do
      fake_client(true, 'Pingback accepted')
      assert_difference 'FeedbackOutgoingPingback.count', 1 do
	FeedbackOutgoingPingback.add_pingback(@node, @target_uri).should_not be_nil
      end

      pingback = FeedbackOutgoingPingback.find(:last)
      pingback.content_node_id.should == @node.id
      pingback.target_uri.should == @target_uri
      pingback.accepted.should be_true
      pingback.status.should == 'Pingback accepted'
    end

    it "should save the outgoing pingback even when it is not accepted" do
      fake_client(false, fake_fault(17, 'Target URL not found'))
      assert_difference 'FeedbackOutgoingPingback.count', 1 do
	FeedbackOutgoingPingback.add_pingback(@node, @target_uri).should_not be_nil
      end

      pingback = FeedbackOutgoingPingback.find(:last)
      pingback.content_node_id.should == @node.id
      pingback.target_uri.should == @target_uri
      pingback.accepted.should be_false
      pingback.status.should == 'Target URL not found'
      pingback.status_code.should == 17
    end

    it "should save the outgoing pingback even if send_pingback raise exception" do
      @client = mock 
      @client.should_receive(:send_pingback).once.and_raise("pingback uri not found")
      FeedbackPingbackClient.should_receive(:new).and_return(@client)

      assert_difference 'FeedbackOutgoingPingback.count', 1 do
	FeedbackOutgoingPingback.add_pingback(@node, @target_uri).should_not be_nil
      end

      pingback = FeedbackOutgoingPingback.find(:last)
      pingback.content_node_id.should == @node.id
      pingback.target_uri.should == @target_uri
      pingback.accepted.should be_nil
      pingback.status.should == 'pingback uri not found'
    end
  end
end
