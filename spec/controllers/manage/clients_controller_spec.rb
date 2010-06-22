require File.dirname(__FILE__) + "/../../spec_helper"

describe Manage::ClientsController do

  reset_system_tables :client_users, :clients, :domains, :domain_databases
  reset_domain_tables :end_users

  before(:each) do
    @domain = Domain.find CMS_DEFAULTS['testing_domain']
    @client = @domain.client
  end

  it "should only permit system administrators" do
    @user = @client.client_users.create :username => 'my_system_admin', :client_admin => 1, :system_admin => 1
    @myself = @user.end_user
    controller.should_receive('myself').at_least(:once).and_return(@myself)
    get 'index'
    response.should render_template('list')
  end

  it "should redirect if not a system admin" do
    @user = @client.client_users.create :username => 'my_system_admin', :client_admin => 1, :system_admin => 0
    @myself = @user.end_user
    controller.should_receive('myself').at_least(:once).and_return(@myself)
    get 'index'
    response.should redirect_to(:controller => '/manage/access', :action => 'denied')
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

  describe "System Administrators" do
    before(:each) do
      @user = @client.client_users.create :username => 'my_system_admin', :client_admin => 1, :system_admin => 1
      @myself = @user.end_user
      controller.should_receive('myself').at_least(:once).and_return(@myself)
    end

    it "should handle client list" do
      # Test all the permutations of an active table
      controller.should handle_active_table(:client_table) do |args|
        post 'display_client_table', args
      end
    end

    it "should render list page" do
      get 'list'
      response.should render_template('list')
    end

    it "should render new page" do
      get 'new'
      response.should render_template('new')
    end

    it "should render edit page" do
      @client = Client.create :name => 'New Client'
      @client.id.should_not be_nil
      get 'edit', :path => [@client.id]
      response.should render_template('edit')
    end

    it "should redirect to list page" do
      get 'create'
      response.should redirect_to(:action => 'list')
    end

    it "should redirect to list page" do
      get 'update'
      response.should redirect_to(:action => 'list')
    end

    it "should redirect to list page" do
      get 'destroy'
      response.should redirect_to(:action => 'list')
    end

    it "should be able to create a new client" do
      assert_difference 'Client.count', 1 do
        post 'create', :client => {:name => 'New Client'}
      end

      response.should redirect_to(:action => 'list')

      @client = Client.find :last
      @client.name.should == 'New Client'
    end

    it "should be able to edit a client" do
      @client = Client.create :name => 'New Client'
      @client.id.should_not be_nil

      assert_difference 'Client.count', 0 do
        post 'update', :path => [@client.id], :client => {:name => 'Client Name Changed'}
      end

      response.should redirect_to(:action => 'index')

      @client.reload
      @client.name.should == 'Client Name Changed'
    end

    it "should be able to destroy a client" do
      @client = Client.create :name => 'New Client'
      @client.id.should_not be_nil

      assert_difference 'Client.count', -1 do
        post 'destroy', :path => [@client.id]
      end

      response.should redirect_to(:action => 'list')

      @client = Client.find_by_id @client.id
      @client.should be_nil
    end
  end
end
