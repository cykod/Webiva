require File.dirname(__FILE__) + "/../spec_helper"

describe DomainLogVisitor do

  reset_domain_tables :domain_log_visitors, :domain_log_sessions, :end_users, :end_user_cache,:end_user_addresses

  before(:each) do
    @user = EndUser.new 
    @session_id = DomainModel.generate_hash # Make a session up
    @session = {}
    @ip_address = "127.0.0.1"
    @cookies = {}
    @request = mock :remote_ip => @ip_address
  end
  

  it "should be able to log a visitor" do
    Proc.new {
      DomainLogVisitor.log_visitor(@cookies,@user,@session,@request)
    }.should change { DomainLogVisitor.count }.by(1)

    dlv = DomainLogVisitor.first
    @cookies[:v][:value].should ==  dlv.visitor_hash
    @session[:domain_log_visitor][:id].should == dlv.id
    dlv.ip_address.should == @ip_address
  end

  it "should be able to us an existing cookie for a new session" do
    DomainLogVisitor.log_visitor(@cookies,@user,@session,@request)
    @session = {}

    dlv = DomainLogVisitor.first

    Proc.new {
      @cookies[:v] = @cookies[:v][:value]
     DomainLogVisitor.log_visitor(@cookies,@user,@session,@request)
    }.should change { DomainLogVisitor.count }.by(0)
    
    @session[:domain_log_visitor][:id].should == dlv.id
  end

  it "should be able to update the user id for new user" do
    DomainLogVisitor.log_visitor(@cookies,@user,@session,@request)

    usr =EndUser.push_target("tester@cykod.com")

    dlv = DomainLogVisitor.first.end_user_id.should be_nil

    @session = {}
    @cookies[:v] = @cookies[:v][:value]
    DomainLogVisitor.log_visitor(@cookies,usr,@session,@request)

    dlv = DomainLogVisitor.first.end_user_id.should == usr.id
  end



end
