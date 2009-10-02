require File.dirname(__FILE__) + "/../spec_helper"

describe Role do

  reset_domain_tables :end_users,:roles, :user_roles, :user_classes
  
  before(:each) do
    UserClass.create_built_in_classes

    
  end

  it "should be able to create a role" do
    Role.count.should == 0

    obj = Role.role_item('dummy_permission')

    Role.count.should == 1
  end


  it "should be able to assign a role to a user class" do

    Role.count.should == 0
    UserRole.count.should == 0
    
    UserClass.domain_user_class.has_role('dummy_role')

    Role.count.should == 1
    UserRole.count.should == 1

    UserClass.domain_user_class.roles.length.should == 1

    UserClass.domain_user_class.has_role('other_dummy_role')

    Role.count.should == 2
    UserRole.count.should == 2
    
  end


  it "should be able to remove a role from a user class" do
    UserClass.domain_user_class.has_role('dummy_role')

    Role.count.should == 1
    UserRole.count.should == 1

    UserClass.domain_user_class.has_no_role('dummy_role')
    
    Role.count.should == 0
    UserRole.count.should == 0
  end

  it "should be able to check a user for roles" do
    UserClass.domain_user_class.has_role('dummy_role')

    usr = EndUser.push_target('test@tester.com',:user_class_id => UserClass.domain_user_class_id)

    usr.has_role?('unknown_dummy_role').should be_false
    usr.has_role?('dummy_role').should be_true
  end


end
