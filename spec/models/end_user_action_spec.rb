require File.dirname(__FILE__) + "/../spec_helper"

describe EndUserAction do

  reset_domain_tables :end_users, :end_user_actions
  

  context "creating actions" do
    before(:each) do
      @user = EndUser.push_target("pascal@cykod.com")
    end
    
    it "should be able to log an action from a simple call" do
      act = EndUserAction.log_action(@user,"/test/tester")
      act.should be_valid
      act.should_not be_custom
      act.renderer.should == 'test'
      act.action.should == 'tester'
    end
    
    it "should be able to log a custom action" do
     act = EndUserAction.log_custom_action(@user,"legacy_purchase","Product 1771")
     act.should be_valid
     act.should be_custom
     act.renderer.should == 'custom'
     act.action.should == 'legacy_purchase'
     act.identifier.should == 'Product 1771'
     act.admin_user.should be_nil
    end
    
    it "should be able to override action_at and admin_user" do 
      @admin_user = EndUser.push_target("admin@cykod.com")
      @fake_time = Time.mktime(2008,1,1)
      
      act = EndUserAction.log_custom_action(@user,"admin_action","Custom Action",:admin_user => @admin_user,:action_at => @fake_time)
      act.should be_valid
      act.admin_user.should == @admin_user
      act.action_at.should == @fake_time
    end
    

    it "should be able push action directly from the user" do 
      act = @user.action("/test/tester")
      act.should be_valid
      act.renderer.should == 'test'
      act.action.should == 'tester'
      act.end_user.should == @user
    end
    
    it "should print a human readable name" do
      act = EndUserAction.log_action(@user,"/test/tester")
      act.should be_valid
      act.description.should == 'Test Tester'
    end

  end
  
  
end
