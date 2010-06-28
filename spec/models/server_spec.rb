require File.dirname(__FILE__) + "/../spec_helper"

describe Server do

  reset_system_tables :servers

  it "should require a hostname" do
    @server = Server.new
    @server.should have(1).errors_on(:hostname)
  end

  it "should be able to create a server" do
    @server = Server.create :hostname => 'my-test-server-09.dev'
    @server.id.should_not be_nil

    @server.link('/send').should == 'http://my-test-server-09.dev/send'
  end
end
