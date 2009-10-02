require File.dirname(__FILE__) + "/../spec_helper"

describe DomainLogSession do

  before(:each) do
    @user = EndUser.new 
    @session_id = DomainModel.generate_hash # Make up a session up
    @ip_address = "127.0.0.1"
  end
  

  it "user should be able to log an entry and updated it" do
    ses = DomainLogSession.session(@session_id,@user,@ip_address)
    ses.should be_valid
    ses.session_id.should == @session_id
    ses.end_user_id.should == @user.id
    
    original_id = ses.id # Save the original id of the session object
    
    # Simulate a user login 
    @new_user = EndUser.create(:user_class_id => UserClass.default_user_class_id,:email => 'pascal@cykod.com')
    
    ses = DomainLogSession.session(@session_id,@new_user,@ip_address)
    ses.id.should ==  original_id # Make sure we still have the same session object
    
    ses.end_user_id.should == @new_user.id
    
  end
  
  it "should pull count from the DB if it hasn't been calculated" do
    ses = DomainLogSession.session(@session_id,@user,@ip_address)
    ses.page_count.should == 0
    entry = DomainLogEntry.create_entry(@user,nil,'test',@ip_address,@session_id,200,nil)
    ses.page_count.should == 1 # should be able to pull the page count
    entry = DomainLogEntry.create_entry(@user,nil,'test',@ip_address,@session_id,200,nil)
    ses.page_count.should == 2 # should be able to pull the page count
  end
  
  
  it "should have the page count update if it has been calculated" do
    ses = DomainLogSession.session(@session_id,@user,@ip_address)
    ses.read_attribute(:page_count).should == nil
    entry = DomainLogEntry.create_entry(@user,nil,'test',@ip_address,@session_id,200,nil)
    ses.calculate!
    ses.read_attribute(:page_count).should == 1 # should be able to pull the pages
    entry = DomainLogEntry.create_entry(@user,nil,'test',@ip_address,@session_id,200,nil)
    ses.calculate!
    ses.read_attribute(:page_count).should == 2 # should be able to pull the pages
  end
  
  it "should return an unsaved entry if asked" do
    ses = DomainLogSession.session(@session_id,@user,@ip_address,false)
    ses.id.should == nil
  end
  
end
