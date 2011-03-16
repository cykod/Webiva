require File.dirname(__FILE__) + "/../spec_helper"

describe ClientUser do

  reset_system_tables :clients, :client_users, :domains, :domain_databases
  reset_domain_tables :end_users

  it "should be a valid client user" do
    @user = ClientUser.new
    @user.should have(1).errors_on(:username)
    @user.should have(1).errors_on(:client_id)
  end

  it "should be able to create a client user" do
    @client = Client.create :name => 'New Client'
    @client.id.should_not be_nil
    @user = @client.client_users.create :username => 'my_test_user'
    @user.id.should_not be_nil

    @user = @client.client_users.create :username => 'my_test_user'
    @user.id.should be_nil
  end

  it "should be able to setup the password and login" do
    @client = Client.create :name => 'New Client'
    @client.id.should_not be_nil
    @user = @client.client_users.create :username => 'my_test_user', :password => 'salt-this'
    @user.id.should_not be_nil
    @user.hashed_password.should_not be_nil
    @user.salt.should_not be_nil

    @user.name.should == 'my_test_user'
    @user.identifier_name.should == "CLIENT USER:#{@user.username} (#{@user.id})"
    @user.validate_password('unknown').should be_false
    @user.validate_password('salt-this').should be_true

    @user = ClientUser.login_by_name 'my_test_user', 'unknown', @client.id
    @user.should be_nil

    @user = ClientUser.login_by_name 'my_test_user', 'salt-this', @client.id
    @user.should_not be_nil

    @user.password = 'new-password'
    @user.save

    @user = ClientUser.login_by_name 'my_test_user', 'salt-this', @client.id
    @user.should be_nil

    @user = ClientUser.login_by_name 'my_test_user', 'new-password', @client.id
    @user.should_not be_nil
  end

  it "should create an end user" do
    @domain = Domain.find CMS_DEFAULTS['testing_domain']
    @domain.id.should_not be_nil
    @user = @domain.client.client_users.create :username => 'my_test_user', :password => 'salt-this'
    @user.id.should_not be_nil

    assert_difference 'EndUser.count', 1 do
      @end_user = @user.end_user
    end

    @end_user.client_user_id.should == @user.id

    @user = ClientUser.find @user.id
    assert_difference 'EndUser.count', 0 do
      @end_user = @user.end_user
    end

    @end_user.client_user_id.should == @user.id
  end
end
