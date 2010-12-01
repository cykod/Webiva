require File.dirname(__FILE__) + "/../spec_helper"

describe DomainLogSession do

  reset_domain_tables :domain_log_sessions, :domain_log_entries, :domain_log_referrers, :domain_log_visitors, :domain_log_groups, :end_users

  before(:each) do
    @user = EndUser.new 
    @session_id = DomainModel.generate_hash[0..31] # Make up a session up
    @ip_address = "127.0.0.1"
    @visitor_id = 1
  end
  

  it "user should be able to log an entry and updated it" do

    ses = DomainLogSession.session(@visitor_id,@session_id,@user,@ip_address)
    ses.should be_valid
    ses.session_id.should == @session_id
    ses.end_user_id.should == @user.id
    
    original_id = ses.id # Save the original id of the session object
    
    # Simulate a user login 
    @new_user = EndUser.create(:user_class_id => UserClass.default_user_class_id,:email => 'pascal@cykod.com')
    
    ses = DomainLogSession.session(@visitor_id,@session_id,@new_user,@ip_address)
    ses.id.should ==  original_id # Make sure we still have the same session object
    
    ses.end_user_id.should == @new_user.id
    
  end
  
  it "should pull count from the DB if it hasn't been calculated" do
    ses = DomainLogSession.session(@visitor_id,@session_id,@user,@ip_address)
    ses.page_count.should == 0
    entry = DomainLogEntry.create_entry(@user,nil,'test',ses.id,200,nil)
    ses.page_count.should == 1 # should be able to pull the page count
    entry = DomainLogEntry.create_entry(@user,nil,'test',ses.id,200,nil)
    ses.page_count.should == 2 # should be able to pull the page count
  end
  
  
  it "should have the page count update if it has been calculated" do
    ses = DomainLogSession.session(@visitor_id,@session_id,@user,@ip_address)
    ses.read_attribute(:page_count).should == nil
    entry = DomainLogEntry.create_entry(@user,nil,'test',ses.id,200,nil)
    ses.calculate!
    ses.read_attribute(:page_count).should == 1 # should be able to pull the pages
    entry = DomainLogEntry.create_entry(@user,nil,'test',ses.id,200,nil)
    ses.calculate!
    ses.read_attribute(:page_count).should == 2 # should be able to pull the pages
  end
  
  it "should return an unsaved entry if asked" do
    ses = DomainLogSession.session(@visitor_id,@session_id,@user,@ip_address,false)
    ses.id.should == nil
  end
  
  it "should be able to start a session" do
    session = {}
    request = mock :referrer => 'http://www.aff.dev/test.html?x=test#first', :parameters => {'affid' => 'test', 'c' => 'testcamp', 'o' => 'testorigin', 'f' => 'free'}, :session_options => {:id => @session_id}, :remote_ip => @ip_address
    DomainLogSession.start_session @user, session, request
    ses = DomainLogSession.find_by_session_id(@session_id)
    ses.should_not be_nil
    ses.session_id.should == @session_id
    ses.affiliate.should == 'test'
    ses.campaign.should == 'testcamp'
    ses.origin.should == 'testorigin'
    ses.affiliate_data.should == 'free'

    # should not create new sessions if session already exists
    assert_difference 'DomainLogSession.count', 0 do
      request = mock :referrer => 'http://www.aff.dev/home.html', :parameters => {}, :session_options => {:id => @session_id}, :remote_ip => @ip_address
      DomainLogSession.start_session @user, session, request
    end

    ses.domain_log_referrer.referrer_domain.should == 'aff.dev'
    ses.domain_log_referrer.referrer_path.should == '/test.html'

    @session_id = DomainModel.generate_hash[0..31] # Make up a session up
    session = {}
    request = mock :referrer => "http://#{DomainModel.active_domain_name}/test.html", :parameters => {'affid' => 'test', 'c' => 'testcamp', 'o' => 'testorigin', 'f' => 'free'}, :session_options => {:id => @session_id}, :remote_ip => @ip_address
    DomainLogSession.start_session @user, session, request
    ses = DomainLogSession.find_by_session_id(@session_id)
    ses.should_not be_nil
    ses.session_id.should == @session_id
    ses.affiliate.should == 'test'
    ses.campaign.should == 'testcamp'
    ses.origin.should == 'testorigin'
    ses.affiliate_data.should == 'free'

    ses.domain_log_referrer.should be_nil

   end
end
