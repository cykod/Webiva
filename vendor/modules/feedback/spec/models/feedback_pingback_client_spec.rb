require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

describe FeedbackPingbackClient do

  def fake_response(pingback_url, body)
    @response = mock :body => body
    @response.should_receive(:[]).with('X-Pingback').any_number_of_times.and_return(pingback_url)
    @response
  end

  def fake_net_http(response)
    @http = mock
    @http.should_receive(:request_get).and_yield(response)
    Net::HTTP.should_receive(:start).and_yield(@http)
  end

  before(:each) do
    @source_uri = Configuration.domain_link @link
    @target_uri = 'http://myexternal.test.site.com/test-post'
    @client = FeedbackPingbackClient.new @source_uri, @target_uri
  end

  it "should find the pingback url in the response header" do
    fake_net_http( fake_response('http://test.dev/xmlrpc/pingback', '<html></html>') )
    @client.pingback_uri.should == 'http://test.dev/xmlrpc/pingback'
  end

  it "should find the pingback url in the <link> tag" do
    fake_net_http( fake_response(nil, '<html><head><link rel="pingback" href="http://test.dev/xmlrpc/pingback" /></head><body></body></html>') )
    @client.pingback_uri.should == 'http://test.dev/xmlrpc/pingback'
  end

  it "should return nil if pingback url is not found" do
    fake_net_http( fake_response(nil, '<html><head></head><body></body></html>') )
    @client.pingback_uri.should be_nil
  end

  it "should return nil if exception is raised why fetching target" do
    @http = mock
    @http.should_receive(:request_get).and_raise("page not found")
    Net::HTTP.should_receive(:start).and_yield(@http)
    @client.pingback_uri.should be_nil
  end

  it "should send the pingback" do
    fake_net_http( fake_response('http://test.dev/xmlrpc/pingback', '<html></html>') )
    @rpc_client = mock
    @rpc_client.should_receive(:call2).with('pingback.ping', @source_uri, @target_uri).and_return([true, 'Pingback Accepted'])
    XMLRPC::Client.should_receive(:new2).with('http://test.dev/xmlrpc/pingback').and_return(@rpc_client)
    @client.send_pingback.should == [true, 'Pingback Accepted']
  end

  it "should raise exception if pingback url not found" do
    fake_net_http( fake_response(nil, '<html></html>') )
    lambda{ @client.send_pingback }.should raise_error
  end
end
