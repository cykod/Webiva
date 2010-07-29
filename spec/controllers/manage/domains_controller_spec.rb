require File.dirname(__FILE__) + "/../../spec_helper"

describe Manage::DomainsController do

  reset_system_tables :client_users, :clients, :domains, :domain_databases, :domain_modules
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

    it "should be allowed to access index" do
      get 'index'
      response.should render_template('list')
    end

    it "should be allowed to access domains_table" do
      get 'domains_table'
      response.should render_template('_domains_table')
    end

    it "should be allowed to access add" do
      get 'add'
      response.should render_template('add')
    end

    it "should not be allowed to access any page that requires a domain" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test'
      get 'edit', :path => [@another_domain.id]
      response.should redirect_to(:action => 'index')
    end

    it "should not be allowed to access any page that requires a domain" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test'
      get 'update_module', :path => [@another_domain.id]
      response.should redirect_to(:action => 'index')
    end

    it "should not be allowed to access any page that requires a domain" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'setup', :database => 'another_test'
      get 'setup', :path => [@another_domain.id]
      response.should redirect_to(:action => 'index')
    end

    it "should not be allowed to access any page that requires a domain" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test'
      get 'delete', :path => [@another_domain.id]
      response.should redirect_to(:action => 'index')
    end

    it "should not be allowed to access any page that requires a domain" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test'
      assert_difference 'Domain.count', 0 do
        get 'destroy', :path => [@another_domain.id]
        response.should redirect_to(:action => 'index')
      end
    end

    it "should not be allowed to access any page that requires a domain" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test'
      assert_difference 'Domain.count', 0 do
        post 'destroy', :path => [@another_domain.id]
        response.should redirect_to(:action => 'index')
      end
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
      controller.should handle_active_table(:domains_table) do |args|
        post 'domains_table', args
      end
    end

    it "should render the edit page" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test'
      get 'edit', :path => [@another_domain.id]
      response.should render_template('edit')
    end

    it "should edit a domain" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test'

      assert_difference 'DomainDatabase.count', 1 do
        assert_difference 'Domain.count', 0 do
          post 'edit', :path => [@another_domain.id], :domain => {:email_enabled => 0, :ssl_enabled => 1, :max_file_storage => 9, :name => 'changed.dev', :database => 'webiva'}
        end
      end

      @another_domain.reload
      @another_domain.name.should == 'another-test-domain.dev'
      @another_domain.database.should == 'another_test'
      @another_domain.email_enabled.should be_false
      @another_domain.ssl_enabled.should be_true
      @another_domain.max_file_storage.should == 9

      response.should render_template('edit')
    end

    it "should edit a redirect domain" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :domain_type => 'redirect', :redirect => 'test.dev'

      assert_difference 'DomainDatabase.count', 0 do
        assert_difference 'Domain.count', 0 do
          post 'edit', :path => [@another_domain.id], :domain => {:email_enabled => 1, :ssl_enabled => 1, :max_file_storage => 9, :name => 'changed.dev', :database => 'webiva', :redirect => 'test2.dev'}
        end
      end

      @another_domain.reload
      @another_domain.redirect.should == 'test2.dev'
      @another_domain.name.should == 'another-test-domain.dev'
      @another_domain.database.should == ''
      @another_domain.email_enabled.should be_false
      @another_domain.ssl_enabled.should be_false
      @another_domain.max_file_storage.should be_nil

      response.should render_template('edit')
    end

    it "should not be allowed to edit a domain that is initializing" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initializing'
      get 'edit', :path => [@another_domain.id]
      response.should redirect_to(:action => 'index')
    end

    it "should not be allowed to edit a domain that is setting up" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'setup'
      get 'edit', :path => [@another_domain.id]
      response.should redirect_to(:action => 'setup', :path => [@another_domain.id])
    end

    it "should update a domain module" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test'

      assert_difference 'DomainModule.count', 1 do
        post 'update_module', :path => [@another_domain.id], :mod => 'blog', :access => 'available'
      end

      @domain_modules = DomainModule.all_modules(@another_domain)
      @domain_modules.detect { |md| md[:name] == "Blog" }.should_not be_nil

      response.should redirect_to(:action => 'edit', :path => [@another_domain.id])
    end

    it "should update a domain module" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test'
      blog_module = @another_domain.domain_modules.create :name => 'blog', :access => 'available'

      assert_difference 'DomainModule.count', 0 do
        post 'update_module', :path => [@another_domain.id], :mod => 'blog', :access => 'unavailable'
      end

      blog_module.reload
      blog_module.access.should == 'unavailable'

      response.should redirect_to(:action => 'edit', :path => [@another_domain.id])
    end

    it "should be able to render add a domain" do
      get 'add'
      response.should render_template('add')
    end

    it "should be able to add a domain" do
      assert_difference 'Domain.count', 1 do
        post 'add', :commit => 1, :domain => {:name => 'my-new-domain.dev', :client_id => @another_client.id, :domain_type => 'domain'}
      end
      @new_domain = Domain.find :last
      @new_domain.status.should == 'setup'
      @new_domain.name.should == 'my-new-domain.dev'
      @new_domain.domain_type.should == 'domain'
      response.should redirect_to(:action => 'setup', :path => [@new_domain.id])
    end

    it "should be able to add a redirect domain" do
      assert_difference 'Domain.count', 1 do
        post 'add', :commit => 1, :domain => {:name => 'my-new-domain.dev', :client_id => @another_client.id, :domain_type => 'redirect'}
      end
      @new_domain = Domain.find :last
      @new_domain.status.should == 'setup'
      @new_domain.name.should == 'my-new-domain.dev'
      @new_domain.domain_type.should == 'redirect'
      response.should redirect_to(:action => 'setup', :path => [@new_domain.id])
    end

    it "should not be able to add a domain without committing" do
      assert_difference 'Domain.count', 0 do
        post 'add', :domain => {:name => 'my-new-domain.dev', :client_id => @another_client.id, :domain_type => 'domain'}
      end
      @new_domain = Domain.find_by_name 'my-new-domain.dev'
      @new_domain.should be_nil
      response.should redirect_to(:action => 'index')
    end

    it "should be able to render delete a domain" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test'
      get 'delete', :path => [@another_domain.id]
      response.should render_template('delete')
    end

    it "should not destroy a domain unless posting" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test'
      assert_difference 'Domain.count', 0 do
        get 'destroy', :path => [@another_domain.id]
      end
      response.should redirect_to(:action => 'index')
    end

    it "should destroy a domain" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test'
      assert_difference 'Domain.count', -1 do
        post 'destroy', :path => [@another_domain.id]
      end
      response.should redirect_to(:action => 'index')
    end

    it "should be able to render the setup domain" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'setup'
      get 'setup', :path => [@another_domain.id]
      response.should render_template('setup')
    end

    it "should not be able to render the setup domain for initialized domains" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized'
      get 'setup', :path => [@another_domain.id]
      response.should redirect_to(:action => 'edit', :path => [@another_domain.id])
    end

    it "should not be able to render the setup domain for initializing domains" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initializing'
      get 'setup', :path => [@another_domain.id]
      response.should redirect_to(:action => 'index')
    end

    it "should not be able to render the setup domain for working domains" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'working'
      get 'setup', :path => [@another_domain.id]
      response.should redirect_to(:action => 'index')
    end

    it "should be able to setup a domain with a new database" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'setup'
      DomainModel.should_receive(:run_worker).with('Domain', @another_domain.id, 'initialize_database', {:max_file_storage=>10240})
      post 'setup', :path => [@another_domain.id], :domain => {:database => 'create'}
      @another_domain.reload
      @another_domain.status.should == 'initializing'
      response.should redirect_to(:action => 'index')
    end

    it "should be able to copy a domain" do
      @copy_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'initialized', :database => 'another_test_db'
      @another_domain = @another_client.domains.create :name => 'another-test-domain-copy.dev', :status => 'setup'
      post 'setup', :path => [@another_domain.id], :domain => {:database => @copy_domain.id}
      @another_domain.reload
      @another_domain.status.should == 'initialized'
      response.should redirect_to(:action => 'index')
    end

    it "should be able to setup the redirect" do
      @another_domain = @another_client.domains.create :name => 'another-test-domain.dev', :status => 'setup', :domain_type => 'redirect'
      post 'setup', :path => [@another_domain.id], :domain => {:redirect => 'redirect-to-me.dev'}
      @another_domain.reload
      @another_domain.status.should == 'initialized'
      @another_domain.redirect.should == 'redirect-to-me.dev'
      response.should redirect_to(:action => 'index')
    end
  end
end
