require File.dirname(__FILE__) + "/../spec_helper"


describe EndUser do
  reset_domain_tables :end_users, :end_user_tags
  before(:each) do

    @user = EndUser.new
    
    
  end
  
  

  it "user should validate" do
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
  
  it 'should return an error if no password present' do
    first_target = EndUser.push_target("tester@cykod.com")
    first_target.save

    validation = first_target.validate
  end

  it 'should create a user tag' do
    EndUser.push_target("user2@webiva.com")
    @user2 = EndUser.find(:last)  
    @user2.tag_names_add('bunnies')
    @user2.tag_names_add('piglets')
    
    @user2.tag_cache_tags.should == 'bunnies,piglets'
  end

  it 'should remove a user tag' do
    EndUser.push_target("USER2@webiva.com")
    @user2 = EndUser.find(:last)

    @user2.tag_names_add('piglets')
    @user2.tag_remove('bunnies')
    @user2.tag_cache_tags.should_not include('bunnies')

  end
  
  it 'should update a users current tags' do
    @user1 = EndUser.push_target("USER2@webiva.com")
    @user1.tag_names_add('piglets')    
    @user1.tag_names_add('bunnies')
    @user1.tag_names=('rhinos,tigers')
    @user1.tag_cache_tags.should == "rhinos,tigers"
end

  it 'should return users searched tags' do
    @user1 = EndUser.push_target("USERa@webiva.com")
    @user2 = EndUser.push_target("USERb@webiva.com")
    @user3 = EndUser.push_target("USERc@webiva.com")
    @user4 = EndUser.push_target("USERd@webiva.com")
    @user5 = EndUser.push_target("USERe@webiva.com")

    @user1.tag_names_add('piglets')
    @user2.tag_names_add('bunnies')
    @user3.tag_names_add('bunnies')
    @user4.tag_names_add('bunnies')
    @user5.tag_names_add('bunnies')

    @userlist = EndUser.find_tagged_with({:any => 'bunnies'})
    @userlist[0].id.should == @user2.id
    @userlist[1].id.should == @user3.id
    @userlist[2].id.should == @user4.id
    @userlist[3].id.should == @user5.id

end
 
  it 'should return users not  searched tags' do
    @user1 = EndUser.push_target("USERa@webiva.com")
    @user2 = EndUser.push_target("USERb@webiva.com")
    @user3 = EndUser.push_target("USERc@webiva.com")
    @user4 = EndUser.push_target("USERd@webiva.com")
    @user5 = EndUser.push_target("USERe@webiva.com")

    @user1.tag_names_add('piglets')
    @user2.tag_names_add('bunnies')
    @user3.tag_names_add('bunnies')
    @user4.tag_names_add('bunnies')
    @user5.tag_names_add('bunnies')

    @userlist = EndUser.find_not_tagged_with({:any => 'bunnies'})
    @userlist[0].id.should == @user1.id

end
  it 'should count users with a searched tag' do
    @user1 = EndUser.push_target("USER2@webiva.com")
    @user2 = EndUser.push_target("USER3@webiva.com")
 

    @user1.tag_names_add('piglets')    
    @user1.tag_names_add('bunnies')
    @user2.tag_names_add('piglets')    
    @user2.tag_names_add('bunnies')

    @usercount = EndUser.count_tagged_with({:any => 'bunnies'})
    @usercount.should == 2
end
  it 'should dont count users with a searched tag' do
    @user1 = EndUser.push_target("USER2@webiva.com")
    @user2 = EndUser.push_target("USER3@webiva.com")
 

    @user1.tag_names_add('piglets')    
    @user1.tag_names_add('bunnies')
    @user2.tag_names_add('piglets')    
    @user2.tag_names_add('bunnies')

    @usercount = EndUser.count_not_tagged_with({:any => 'bunnies'})
    @usercount.should == 2
end
  it 'should create a hashed passwd for new users' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    @pass_check = EndUser.find_by_id(@user1.id)
    @pass_check.hashed_password.should_not be_nil

  end

end
