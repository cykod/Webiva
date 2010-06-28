require File.dirname(__FILE__) + "/../../spec_helper"

describe Manage::UsersController do

  reset_system_tables :client_users, :clients, :domains, :domain_databases
  reset_domain_tables :end_users

  before(:each) do
    @domain = Domain.find CMS_DEFAULTS['testing_domain']
    @client = @domain.client
  end

  it "should permit system administrators" do
    @user = @client.client_users.create :username => 'my_system_admin', :client_admin => 1, :system_admin => 1
    @myself = @user.end_user
    controller.should_receive('myself').at_least(:once).and_return(@myself)
    get 'index'
    response.should render_template('list')
  end

  it "should permit client administrators" do
    @user = @client.client_users.create :username => 'my_system_admin', :client_admin => 1, :system_admin => 0
    @myself = @user.end_user
    controller.should_receive('myself').at_least(:once).and_return(@myself)
    get 'index'
    response.should render_template('list')
  end

  it "should redirect if not a system admin" do
    @user = @client.client_users.create :username => 'my_system_admin', :client_admin => 0, :system_admin => 0
    @myself = @user.end_user
    controller.should_receive('myself').at_least(:once).and_return(@myself)
    get 'index'
    response.should redirect_to(:controller => '/manage/access', :action => 'denied')
  end

  it "should redirect if not a system admin" do
    mock_user
    get 'index'
    response.should redirect_to(:controller => '/manage/access', :action => 'denied')
  end

  it "should redirect if not a system admin" do
    get 'index'
    response.should redirect_to(:controller => '/manage/access', :action => 'denied')
  end

  describe "Client Administrators" do
    before(:each) do
      @user = @client.client_users.create :username => 'my_system_admin', :client_admin => 1, :system_admin => 0
      @myself = @user.end_user
      controller.should_receive('myself').at_least(:once).and_return(@myself)

      @another_client = Client.create :name => 'Not My Client'
    end

    it "should handle domain list" do
      # Test all the permutations of an active table
      controller.should handle_active_table(:client_users_table) do |args|
        post 'display_client_users_table', args
      end
    end

    it "should be able to create a user" do
      assert_difference 'ClientUser.count', 1 do
        post 'edit', :path => [], :commit => 1, :client_user => {:username => 'new_admin_user', :password => 'password', :domain_database_id => nil, :client_admin => true, :system_admin => true}
      end

      @new_user = ClientUser.find :last
      @new_user.username.should == 'new_admin_user'
      @new_user.client_admin?.should be_true
      @new_user.system_admin?.should be_false

      response.should redirect_to(:action => 'index')
    end

    it "should not be able to create a user if you do not commit" do
      assert_difference 'ClientUser.count', 0 do
        post 'edit', :path => [], :client_user => {:username => 'new_admin_user', :password => 'password', :domain_database_id => nil, :client_admin => true}
      end

      @new_user = ClientUser.find_by_username  'new_admin_user'
      @new_user.should be_nil

      response.should redirect_to(:action => 'index')
    end

    it "should be able to edit a user" do
      @user_to_edit = @client.client_users.create :username => 'my_admin_to_edit', :client_admin => 1, :system_admin => 0

      assert_difference 'ClientUser.count', 0 do
        post 'edit', :path => [@user_to_edit.id], :commit => 1, :client_user => {:username => 'new_admin_user', :password => 'password', :domain_database_id => nil, :client_admin => false, :system_admin => true}
      end

      @user_to_edit.reload
      @user_to_edit.username.should == 'new_admin_user'
      @user_to_edit.client_admin?.should be_false
      @user_to_edit.system_admin?.should be_false

      response.should redirect_to(:action => 'index')
    end

    it "should be redirect to edit if trying to use edit_all" do
      @user_to_edit = @client.client_users.create :username => 'my_admin_to_edit', :client_admin => 1, :system_admin => 0

      assert_difference 'ClientUser.count', 0 do
        get 'edit_all', :path => [@user_to_edit.id]
      end

      response.should redirect_to(:action => 'edit', :path => [@user_to_edit.id])
    end

    it "should be redirect to index if trying to edit a system admin" do
      @admin_user = @client.client_users.create :username => 'my_admin_to_edit', :client_admin => 1, :system_admin => 1
      get 'edit', :path => [@admin_user.id]
      response.should redirect_to(:action => 'index')
    end

    it "should not be able to edit users from a different client" do
      @other_client_user = @another_client.client_users.create :username => 'my_admin_to_edit', :client_admin => 1, :system_admin => 0
      get 'edit', :path => [@other_client_user.id]
      response.should render_template('edit')
    end

    it "should be able to destroy a user" do
      @user = @client.client_users.create :username => 'my_admin_to_edit', :client_admin => 1, :system_admin => 0
      assert_difference 'ClientUser.count', -1 do
        post 'destroy', :path => [@user.id]
      end
      response.should redirect_to(:action => 'index')
    end

    it "should not be able to destroy a sys admin" do
      @user = @client.client_users.create :username => 'my_admin_to_edit', :client_admin => 1, :system_admin => 1
      assert_difference 'ClientUser.count', 0 do
        post 'destroy', :path => [@user.id]
      end
      response.should redirect_to(:action => 'index')
    end

    it "should not be able to destroy a user from a different client" do
      @user = @another_client.client_users.create :username => 'my_admin_to_edit', :client_admin => 1, :system_admin => 0
      assert_difference 'ClientUser.count', 0 do
        post 'destroy', :path => [@user.id]
      end
      response.should redirect_to(:action => 'index')
    end

    it "should not be able to destroy yourself" do
      assert_difference 'ClientUser.count', 0 do
        post 'destroy', :path => [@user.id]
      end
      response.should redirect_to(:action => 'index')
    end
  end

  describe "System Administrators" do
    before(:each) do
      @user = @client.client_users.create :username => 'my_system_admin', :client_admin => 1, :system_admin => 1
      @myself = @user.end_user
      controller.should_receive('myself').at_least(:once).and_return(@myself)

      @another_client = Client.create :name => 'Not My Client'
    end

    it "should handle domain list" do
      # Test all the permutations of an active table
      controller.should handle_active_table(:client_users_table) do |args|
        post 'display_client_users_table', args
      end
    end

    it "should be redirect to edit_all if trying to use edit" do
      @user_to_edit = @client.client_users.create :username => 'my_admin_to_edit', :client_admin => 1, :system_admin => 1

      assert_difference 'ClientUser.count', 0 do
        get 'edit', :path => [@user_to_edit.id]
      end

      response.should redirect_to(:action => 'edit_all', :path => [@user_to_edit.id])
    end

    it "should be able to destroy a user" do
      @user = @client.client_users.create :username => 'my_admin_to_edit', :client_admin => 1, :system_admin => 0
      assert_difference 'ClientUser.count', -1 do
        post 'destroy', :path => [@user.id]
      end
      response.should redirect_to(:action => 'index')
    end

    it "should be able to destroy a sys admin" do
      @user = @client.client_users.create :username => 'my_admin_to_edit', :client_admin => 1, :system_admin => 1
      assert_difference 'ClientUser.count', -1 do
        post 'destroy', :path => [@user.id]
      end
      response.should redirect_to(:action => 'index')
    end

    it "should be able to destroy a user from a different client" do
      @user = @another_client.client_users.create :username => 'my_admin_to_edit', :client_admin => 1, :system_admin => 0
      assert_difference 'ClientUser.count', -1 do
        post 'destroy', :path => [@user.id]
      end
      response.should redirect_to(:action => 'index')
    end

    it "should not be able to destroy yourself" do
      assert_difference 'ClientUser.count', 0 do
        post 'destroy', :path => [@user.id]
      end
      response.should redirect_to(:action => 'index')
    end

    it "should be able to edit a user" do
      @user_to_edit = @another_client.client_users.create :username => 'my_admin_to_edit', :client_admin => 1, :system_admin => 0

      assert_difference 'ClientUser.count', 0 do
        post 'edit_all', :path => [@user_to_edit.id], :commit => 1, :client_user => {:username => 'new_admin_user', :password => 'password', :domain_database_id => nil, :client_admin => false, :system_admin => true}
      end

      @user_to_edit.reload
      @user_to_edit.username.should == 'new_admin_user'
      @user_to_edit.client_admin?.should be_false
      @user_to_edit.system_admin?.should be_true

      response.should redirect_to(:action => 'index')
    end

    it "should be able to create a user" do
      controller.session[:active_client_company] = @client.id

      assert_difference 'ClientUser.count', 1 do
        post 'edit_all', :path => [], :commit => 1, :client_user => {:username => 'new_admin_user', :password => 'password', :domain_database_id => nil, :client_admin => true, :system_admin => true}
      end

      @user_to_edit = ClientUser.find :last
      @user_to_edit.username.should == 'new_admin_user'
      @user_to_edit.client_admin?.should be_true
      @user_to_edit.system_admin?.should be_true

      response.should redirect_to(:action => 'index')
    end

    it "should not be able to create a user unless committing" do
      assert_difference 'ClientUser.count', 0 do
        post 'edit_all', :path => [], :client_user => {:username => 'new_admin_user', :password => 'password', :domain_database_id => nil, :client_admin => true, :system_admin => true}
      end

      @user_to_edit = ClientUser.find_by_username 'new_admin_user'
      @user_to_edit.should be_nil

      response.should redirect_to(:action => 'index')
    end
  end
end
