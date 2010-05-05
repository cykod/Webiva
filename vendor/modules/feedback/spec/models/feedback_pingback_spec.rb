require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

describe FeedbackPingback do

  reset_domain_tables :feedback_pingbacks, :comments, :content_nodes, :content_node_values, :blog_posts, :blog_blogs, :blog_post_revisions

  def fake_response(body)
    @response = mock :body => body, :value => 200
    @response
  end

  def fake_net_http(response)
    @http = mock
    @http.should_receive(:request_get).and_yield(response)
    Net::HTTP.should_receive(:start).and_yield(@http)
  end

  it "should require content, source and target" do
    @comment = FeedbackPingback.new
    @comment.valid?
    @comment.should have(1).errors_on(:content_node_id)
    @comment.should have(1).errors_on(:source_uri)
    @comment.should have(1).errors_on(:target_uri)
  end

  it "should error if source uri is invalid" do
    lambda { FeedbackPingback.retrieve_source_content('invalid url') }.should raise_error
  end

  it "should error if source uri is invalid" do
    lambda { FeedbackPingback.retrieve_source_content('invalid url') }.should raise_error
  end

  it "should error if source uri does not exists" do
    lambda { FeedbackPingback.retrieve_source_content('http://test.dev/asdf') }.should raise_error
  end

  it "should process incoming pingback request" do
    link = '/asdf'
    fake_net_http(fake_response('Test Body'))
    body = nil
    lambda { body = FeedbackPingback.retrieve_source_content("http://test.dev#{link}") }.should_not raise_error
    body.should == 'Test Body'
  end

  describe "processing pingbacks" do
    before(:each) do
      blog = Blog::BlogBlog.create(:name=>'Blog',:content_filter => 'full_html' )
      @post = blog.blog_posts.create(:title => 'Test Title', :body => 'Test Body')
      @link = '/test-post'
      @type = ContentType.create :component => 'blog', :container_type => 'Blog::BlogBlog', :container_id => 1, :content_type => 'Blog::BlogPost', :content_name => 'Mock Blog', :title_field => 'title'
      @node = @type.content_nodes.create :node => @post
      @node_value = @node.content_node_values.create :content_type_id => @type.id, :link => @link
      @source_uri = 'http://myexternal.test.site.com/test-post'
      @target_uri = Configuration.domain_link @link
    end

    it "should get content node" do
      content_node = FeedbackPingback.get_content_node_for_target @target_uri
      content_node.should == @node
    end

    it "should not get content node and raise error if target is invalid" do
      lambda{ content_node = FeedbackPingback.get_content_node_for_target 'invalid url' }.should raise_error
    end

    it "should not get content node and raise error if target is wrong host" do
      lambda{ content_node = FeedbackPingback.get_content_node_for_target 'http://this.is.the.wrong.host.com/post' }.should raise_error
    end

    it "should not get content node and raise error if target is missing path" do
      target = Configuration.domain_link ''
      lambda{ content_node = FeedbackPingback.get_content_node_for_target target }.should raise_error
    end

    it "should not get content node and raise error if target uri can not be found in content node values" do
      target = Configuration.domain_link '/fake-link'
      lambda{ content_node = FeedbackPingback.get_content_node_for_target target }.should raise_error
    end

    it "should not get content node and raise error if target node is protected" do
      @type.protected_results = true
      @type.save
      lambda{ content_node = FeedbackPingback.get_content_node_for_target @target_uri }.should raise_error
    end

    it "should be able to process incoming pingback" do
      FeedbackPingback.should_receive(:retrieve_source_content).and_return("This is a great <a href='#{@target_uri}'>post</a>.")

      assert_difference 'FeedbackPingback.count', 1 do
	FeedbackPingback.process_incoming_ping @source_uri, @target_uri
      end

      pingback = FeedbackPingback.find(:last)
      pingback.source_uri.should == @source_uri
      pingback.target_uri.should == @target_uri
      pingback.content_node_id.should == @node.id
      pingback.title.should == @source_uri
    end

    it "should not process incoming pingbacks twice" do
      FeedbackPingback.should_receive(:retrieve_source_content).and_return("<html><head><title>Test Title</title></head>This is a great <a href='#{@target_uri}'>post</a>.</html>")

      assert_difference 'FeedbackPingback.count', 1 do
	FeedbackPingback.process_incoming_ping @source_uri, @target_uri
      end

      pingback = FeedbackPingback.find(:last)
      pingback.source_uri.should == @source_uri
      pingback.target_uri.should == @target_uri
      pingback.content_node_id.should == @node.id
      pingback.title.should == 'Test Title'

      assert_difference 'FeedbackPingback.count', 0 do
	lambda { FeedbackPingback.process_incoming_ping @source_uri, @target_uri }.should raise_error
      end
    end

    it "should be able to create a comment from a pingback" do
      FeedbackPingback.should_receive(:retrieve_source_content).and_return("<html><head><title>Test Title</title></head>This is a great <a href='#{@target_uri}'>post</a>.</html>")

      assert_difference 'FeedbackPingback.count', 1 do
	FeedbackPingback.process_incoming_ping @source_uri, @target_uri
      end

      pingback = FeedbackPingback.find(:last)
      pingback.source_uri.should == @source_uri
      pingback.target_uri.should == @target_uri
      pingback.content_node_id.should == @node.id
      pingback.title.should == 'Test Title'

      myself = mock :id => 1
      assert_difference 'Comment.count', 1 do
	pingback.create_comment(myself)
      end

      comment = Comment.find(:last)
      comment.website.should == pingback.source_uri
      comment.name.should == pingback.title
      comment.comment.include?(pingback.excerpt).should be_true
      comment.rating.should == 1
      comment.posted_at.should == pingback.posted_at
      comment.target_type.should == 'Blog::BlogPost'
      comment.target_id.should == 1
      comment.rated_by_user_id.should == 1
    end

    it "should be able to create a comment for all pingbacks" do
      FeedbackPingback.should_receive(:retrieve_source_content).and_return("<html><head><title>Test Title</title></head>This is a great <a href='#{@target_uri}'>post</a>.</html>")

      assert_difference 'FeedbackPingback.count', 1 do
	FeedbackPingback.process_incoming_ping @source_uri, @target_uri
      end

      pingback = FeedbackPingback.find(:last)
      pingback.source_uri.should == @source_uri
      pingback.target_uri.should == @target_uri
      pingback.content_node_id.should == @node.id
      pingback.title.should == 'Test Title'

      myself = mock :id => 1
      assert_difference 'Comment.count', 1 do
	FeedbackPingback.create_comments(myself, [pingback.id])
      end

      comment = Comment.find(:last)
      comment.website.should == pingback.source_uri
      comment.name.should == pingback.title
      comment.comment.include?(pingback.excerpt).should be_true
      comment.rating.should == 1
      comment.posted_at.should == pingback.posted_at
      comment.target_type.should == 'Blog::BlogPost'
      comment.target_id.should == 1
      comment.rated_by_user_id.should == 1
    end
  end
end
