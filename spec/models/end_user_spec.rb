require File.dirname(__FILE__) + "/../spec_helper"


describe EndUser do
  reset_domain_tables :end_users, :end_user_tags, :tags, 'tag_cache', :domain_files, :end_user_actions, :configurations, :roles, :user_roles
  before(:each) do
    
    @user = EndUser.new  
  end
  


### End User Creation
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

### Password and Validation
  
  it 'should return an error if no password present' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1)

    @validation = @user1.validate
    @validation.should have_at_least(1).error_on(:password)

  end
  it 'should update verification string on initial password set' do
    
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies')
    
    @old_verification = @user1.verification_string

    @user1.update_verification_string!
    @user1.verification_string.should_not == @old_verification
    
  end
  it 'should validate a users password on log-in' do 
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :activated => 1, :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    
    @user1.validate_password('bunnies').should == true
    
  end
  ### End User Tokens
  
  
  ### User Attributes
  ##### Full Name
  it 'should return a users full name' do 
        @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies')
    @user1.name.should == "User 2"
  end

  it 'should return a users id or display name' do 
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    @findu = EndUser.find_by_email('test1@webiva.com')
    @findu.identifier_name.should == "User 2 (1)"
  end

  it 'should return a users image or default image' do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    @df = DomainFile.create(:filename => fdata) 

    DataCache.reset_local_cache

    ########## set default missing image ids
    @options = Configuration.options(:missing_male_image_id => @df.id, :missing_image_id => @df.id, :missing_female_image_id => @df.id)
    @config = Configuration.retrieve(:options)
    @config.options = @options.to_hash
    @config.save
    Configuration.retrieve(:options)
    ##########

    @user1 = EndUser.push_target("test1@webiva.com")
    @user2 = EndUser.push_target("test2@webiva.com")

    @user1.update_attributes( :first_name=> 'User', :domain_file_id => @df.id, :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')

    @user1.image.id.should == @df.id
    @user2.image.id.should == @df.id

    @df.destroy
  end

  it 'should return an html description' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    @user1.html_description.should == "<table><tr><td>Email:</td><td>test1@webiva.com</td></tr><tr><td>First name:</td><td>User</td></tr><tr><td>Last name:</td><td>2</td></tr><tr><td>Vip number:</td><td></td></tr></table>"
    
  end
  it 'should return an text description' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    @user1.text_description.should == "Email:test1@webiva.com\nFirst name:User\nLast name:2\nVip number:\n\n"
    
  end
  it 'should list array with all user subscriptions, this user has none' do

    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    @user1.subscriptions.should == []
  end
  it 'should return the user language or system default if none' do
   @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    @user1.language.should == 'en'
  end
  it 'should create an array of all users & their options' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    EndUser.select_options.should == [["2, User (#1)", 1]]
  end
  it 'should get or set the user_profile' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    @user1.user_profile.name.should == 'Default'
  end
  it 'should get or set the user_profile id' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    @user1.user_profile_id.should == 4
  end
  it 'should determine if a user is an editor' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    @user1.editor?.should == false
  end
  it 'should login with email and password' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    EndUser.login_by_email('test1@webiva.com','bunnies').should be_valid
  end
  it 'should fail login with email and password' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    EndUser.login_by_email('test2@webiva.com','bunnies').should be_nil
  end
  it 'should login with username and password' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :username => 'bunnilover',  :user_level => 1, :last_name => '2', :activated => 1, :language => 'en' ,:registered => 1,  :password => 'bunnies', :password_confirmation => 'bunnies')
    EndUser.login_by_username('bunnilover','bunnies').should be_valid
  end
  it 'should fail login with username and password' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :username => 'bunnilover',  :user_level => 1, :last_name => '2', :activated => 1, :language => 'en' ,:registered => 1,  :password => 'bunnies', :password_confirmation => 'bunnies')
    EndUser.login_by_username('bunniloverblahblah','bunnies').should be_nil
  end
  
  it 'should fail login with verification token but no user password' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :username => 'bunnilover',  :user_level => 1,
                              :last_name => '2', :activated => 1, :language => 'en' ,:registered => 1)
    @user1.update_verification_string!
    EndUser.login_by_verification(@user1.verification_string).should raise_error
  end
  it 'should login with verification token ' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :username => 'bunnilover',  :user_level => 1, :password => 'bunnies', :password_confirmation => 'bunnies',
                              :last_name => '2', :activated => 1, :language => 'en' ,:registered => 1)
    @user1.update_verification_string!
    EndUser.login_by_verification(@user1.verification_string).should raise_error
  end
  ### End User Tags
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
  
  it 'should return users with searched tags' do
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
  
  it 'should return users without searched tags' do
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
  it 'should not count users with a searched tag' do
    @user1 = EndUser.push_target("USER2@webiva.com")
    @user2 = EndUser.push_target("USER3@webiva.com")
    @user3 = EndUser.push_target("USER4@webiva.com")
    @user4 = EndUser.push_target("USER5@webiva.com")
    
    
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
  it 'should save tags when the user is unsaved' do
  #  @user1 = EndUser.new(:user_class_id => 4)
    @user1 = EndUser.new(:email => 'test1@webiva.com')
    @user1.user_class_id = UserClass.default_user_class_id
    @check_users = EndUser.find(:last)
    @check_users.should be_nil

    @user1.tag('piglets,bunnies,rhinos') 
    @user1.update_attributes(:first_name => 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
   
    @user1.tag_names.should == ["piglets,bunnies,rhinos"]

  end
  ### User Roles
   it 'should return a list of roles associated with a user' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    
    @user1.roles_list.should == []
  end
  ### Log Actions
  it 'should log all called actions' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    @actions = @user1.action('/editor/auth/user_registration', :identifier => @user1.email)
    @actions.id.should == 1
  end 
   it 'should log all custom actions' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en' ,:registered => 1, :password => 'bunnies', :password_confirmation => 'bunnies')
    @actions = EndUserAction.log_custom_action(@user1,"admin_action","Custom Action",:admin_user => @admin_user,:action_at => @fake_time)
    @actions.id.should == 1
  end
  ### Generation

  it 'should generate a vip' do 
  @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en')
    @acivate = EndUser.generate_vip.should_not be_nil
  end
  it 'should generate an activation string' do
  @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en')
    @acivate = @user1.generate_activation_string.should_not be_nil
  end
 it 'should generate random password' do
    @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en')
    
    @pass = EndUser.generate_password
    @pass.should_not be_nil
  end
   it 'should generate random password' do
   @user1 = EndUser.push_target("test1@webiva.com")
    @user1.update_attributes( :first_name=> 'User', :user_level => 1, :last_name => '2', :language => 'en')
    
    @pass = EndUser.generate_password
    @pass.should_not be_nil
    
    @newpass = EndUser.generate_password
    @newpass.should_not == @pass

    
  end
end
