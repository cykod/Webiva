require File.dirname(__FILE__) + "/../../spec_helper"

describe Editor::AuthFeature, :type => :view do

  reset_domain_tables :end_users, :end_user_addresses, :tags, :end_user_tags, :site_nodes, :user_subscriptions, :mail_templates, :user_subscription_entries

  before(:each) do
    @feature = build_feature('/editor/auth_feature')
  end

  it "should display user_register feature" do
    @success_page = SiteVersion.default.root_node.add_subpage('success')
    @options = Editor::AuthController::UserRegisterOptions.new :success_page_id => @success_page.id, :user_class_id => UserClass.default_user_class_id
    @usr = EndUser.new :email => 'test@test.dev'
    @address = @usr.build_address(:address_name => 'Default Address'.t )
    @business = @usr.build_address(:address_name => 'Business Address'.t )

    data = { :options => @options,
             :usr => @usr,
             :address => @address,
             :business => @business
           }
  
    @output = @feature.user_register_feature(data)
    @output.should include('test@test.dev')
  end

  it "should display user_activation feature" do
    opts = {}
    @options = Editor::AuthController::UserActivationOptions.new opts
    @user = EndUser.new

    data = { :options => @options,
             :user => @user,
             :status => 'activation',
             :activation_object => DefaultsHashObject.new(:code => 'testcode', :accept => false )
           }
  
    @output = @feature.user_activation_feature(data)
    @output.should include('testcode')
  end

  it "should display login feature" do
    opts = {}
    @options = Editor::AuthController::LoginOptions.new opts
    @login_user = EndUser.new

    data = { :login_user => @login_user,
             :type => @options.login_type,
             :options => @options
           }
  
    @output = @feature.login_feature(data)
    @output.should include('cms_login[login]')
  end

  it "should display missing_password feature" do
    data = { :invalid => nil,
             :state => 'missing_password'
           }
  
    @output = @feature.missing_password_feature(data)
    @output.should include('missing_password[email]')
  end

  it "should display enter_vip feature" do
    data = { :failure => false,
             :registered => false }
  
    @output = @feature.enter_vip_feature(data)
    @output.should include('vip[number]')
  end

  it "should display email_list feature" do
    @subscription = UserSubscription.create :name => 'Test'
    @destination_page = SiteVersion.default.root_node.add_subpage('destiny')
    @options = Editor::AuthController::UserActivationOptions.new :user_subscription_id => @subscription.id, :destination_page_id => @destination_page.id

    data = { :email_list => Editor::AuthRenderer::EmailListUser.new(:email => 'test@test.dev'),
             :options => @options,
             :submitted => nil }
  
    @output = @feature.email_list_feature(data)
    @output.should include('test@test.dev')
  end

  it "should display view_account feature" do
    @user = EndUser.new :first_name => 'First', :last_name => 'Last'

    data = { :user => @user }
  
    @output = @feature.view_account_feature(data)
    @output.should include('First Last')
  end
end
