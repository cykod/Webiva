require File.dirname(__FILE__) + "/../spec_helper"

describe EndUser do

  before(:each) do
    @user = EndUser.new
  end
  

  it "user should be valid" do
    @user.should_not be_valid
    
  end
  
  
  it "should be able to push a target" do
    target = EndUser.push_target("pascal@cykod.com")
    target.should_not be_new_record
  end
  
  it "should be able to push a target twice and get the same end user" do
    first_target = EndUser.push_target("tester@cykod.com")
    second_target = EndUser.push_target("tester@cykod.com")
    
    first_target.should == second_target
  end
  
  
end
