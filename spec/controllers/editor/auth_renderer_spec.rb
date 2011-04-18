require File.dirname(__FILE__) + "/../../spec_helper"


describe Editor::AuthRenderer, :type => :controller do
  controller_name :page
  
  integrate_views

  reset_domain_tables :end_users, :end_user_addresses, :tags, :end_user_tags, :site_nodes, :user_subscriptions, :mail_templates, :user_subscription_entries

  describe "User Register Paragraph" do 
    def generate_renderer(data = {})
      # Set a user class b/c we need one
      default = { :user_class_id => UserClass.default_user_class_id }
      build_renderer('/page','/editor/auth/user_register',default.merge(data),{})
    end
    
    it "should be able to view the default user paragraph" do
      @rnd = generate_renderer
      
      EndUser.count.should==0

      @rnd.should_render_feature("user_register")
      renderer_get @rnd 
    end

    it "should require a valid email and a password" do
      @rnd = generate_renderer

      EndUser.count.should == 0

      @user = EndUser.new
      EndUser.should_receive(:new).at_least(:once).and_return(@user)

      renderer_post @rnd, :user => { :email => "", :password => "", :password_confirmation => "" }

      @user.should have(1).error_on(:email)
      @user.should have(1).error_on(:password)
    end

    it "should be able to create a user with just an email and a password" do
      @rnd = generate_renderer()

      EndUser.count.should == 0

      renderer_post @rnd, :user => { :email => "test@webiva.com", :password => "test", :password_confirmation => "test" }
      EndUser.count.should == 1
      usr = EndUser.find(:first)
      usr.email.should == 'test@webiva.com'
    end
    
    it "shouldn't let in values that aren't in the optional fields" do
      @rnd = generate_renderer(:optional_fields => ['first_name'] )

      renderer_post @rnd, :user => { :email => "test@webiva.com", :password => "test", :password_confirmation => "test", :first_name => 'Testerama', :last_name => 'McJohnson' }

      EndUser.count.should == 1
      usr = EndUser.find(:first)
      usr.email.should == 'test@webiva.com'
      usr.first_name.should == 'Testerama'
      usr.last_name.should be_blank
    end


    it "should let address fields in" do
      @rnd = generate_renderer()
      renderer_post @rnd, :user => { :email => "test@webiva.com", :password => "test", :password_confirmation => "test" }, :address => { :address => '123 Elm St',:city => 'Boston' }

      EndUser.count.should == 1
      usr = EndUser.find(:first)
      usr.email.should == 'test@webiva.com'
      usr.address.address.should == '123 Elm St'
      usr.address.city.should == 'Boston'
    end

    it "shouldn't save if required address fields aren't there" do
      assert_difference "EndUserAddress.count", 0 do 
        @rnd = generate_renderer(:address_required_fields => ['state'])
        renderer_post @rnd, :user => { :email => "test@webiva.com", :password => "test", :password_confirmation => "test" }, :address => { :address => '123 Elm St',:city => 'Boston' }
      end

    end

    it "should save if all required address fields are there" do
        @rnd = generate_renderer(:address_required_fields => ['state','city','state'])
      renderer_post @rnd, :user => { :email => "test@webiva.com", :password => "test", :password_confirmation => "test" }, :address => { :address => '123 Elm St',:city => 'Boston', :state => 'MA' }

      EndUser.count.should == 1
      usr = EndUser.find(:first)
      usr.address.address.should == '123 Elm St'
      usr.address.city.should == 'Boston'
      usr.address.state.should == 'MA'
      usr.address.country.should == 'United States'
    end

    it "should support information registrations that only require email" do
        @rnd = generate_renderer(:registration_type => 'info')
      renderer_post @rnd, :user => { :email => "test@webiva.com" } 

      EndUser.count.should == 1
      usr = EndUser.find(:first)
      usr.email.should == 'test@webiva.com'
    end

    it "should be able to add tag names" do
      @rnd = generate_renderer(:add_tags => 'test1,test2',:registration_type => 'info')
      renderer_post @rnd, :user => { :email => "test@webiva.com" }
      EndUser.count.should == 1
      usr = EndUser.find(:first)
      usr.tag_names.should == 'Test1, Test2'
    end

    it "should be able to set the user source" do
      @rnd = generate_renderer(:registration_type => 'info',:source =>'tester_source')
      renderer_post @rnd, :user => { :email => "test@webiva.com" }
      EndUser.count.should == 1
      usr = EndUser.find(:first)
      usr.lead_source.should =='tester_source'
    end
    
  end

  describe "User Edit Account Paragraph" do
    before(:each) do
      mock_user
    end

    def generate_renderer(data = {:required_fields => [ ]})
      # Set a user class b/c we need one
      build_renderer('/page','/editor/auth/user_edit_account',data,{})
    end
    
    it "should be able to view the default user edit paragraph" do
      @rnd = generate_renderer
      @rnd.should_render_feature("user_edit_account")
      renderer_get @rnd 
    end

    it "should require a valid email" do
      @rnd = generate_renderer

      renderer_post @rnd, :user => { :email => "", :password => "", :password_confirmation => "" }

      @myself.should have(1).error_on(:email)
    end

    it "should be able to change a user's  email and password" do
      @rnd = generate_renderer()

      renderer_post @rnd, :user => { :email => "test@webiva.com", :password => "test", :password_confirmation => "test" }

      @myself.email.should == 'test@webiva.com'
    end
    
    it "shouldn't let in values that aren't in the optional fields" do
      @rnd = generate_renderer(:optional_fields => ['first_name'] )

      renderer_post @rnd, :user => { :email => "test@webiva.com", :password => "test", :password_confirmation => "test", :first_name => 'Testerama', :last_name => 'McJohnson' }

      @myself.email.should == 'test@webiva.com'
      @myself.first_name.should == 'Testerama'
      @myself.last_name.should be_blank
    end

    it "should let address fields in" do
      @rnd = generate_renderer()
      renderer_post @rnd, :user => { :email => "test@webiva.com", :password => "test", :password_confirmation => "test" }, :address => { :address => '123 Elm St',:city => 'Boston' }

      @myself.email.should == 'test@webiva.com'
      @myself.address.address.should == '123 Elm St'
      @myself.address.city.should == 'Boston'
      @myself.address.country.should == 'United States'
    end

    it "shouldn't save if required address fields aren't there" do
      @rnd = generate_renderer(:address_required_fields => ['state'])
      renderer_post @rnd, :user => { :email => "test@webiva.com", :password => "test", :password_confirmation => "test" }, :address => { :address => '125 Elm St',:city => 'Boston' }

      @myself.address.id.should be_nil
      @usr = EndUser.find @myself.id
      @usr.address.should be_nil
      @myself.address.errors.length.should == 1
      @myself.address.errors.on(:state).should == 'is missing'
    end

    it "should save if all required address fields are there" do
        @rnd = generate_renderer(:address_required_fields => ['state','city','state'])
      renderer_post @rnd, :user => { :email => "test@webiva.com", :password => "test", :password_confirmation => "test" }, :address => { :address => '123 Elm St',:city => 'Boston', :state => 'MA' }

      @myself.address.address.should == '123 Elm St'
      @myself.address.city.should == 'Boston'
      @myself.address.state.should == 'MA'
    end

    it "should be able to add tag names" do
      @rnd = generate_renderer(:add_tags => 'test1,test2',:required_fields => [])
      renderer_post @rnd, :user => { :first_name => 'first' }
      @myself.reload
      @myself.tag_names.should == 'Test1, Test2'
    end

    it "should set access token" do
      token = AccessToken.create :token_name => 'token'
      token.id.should_not be_nil

      @rnd = generate_renderer(:access_token_id => token.id, :required_fields => [])
      renderer_post @rnd, :user => { :first_name => 'First' }

      @myself.errors.length.should == 0
      @myself.first_name.should == 'First'
      @myself.tokens.detect { |t| t.access_token_id == token.id }.should be_true
    end

    it "should send mail" do
      @email_template = MailTemplate.find_by_name('edit') || MailTemplate.create(:subject => 'Account Updated', :name => 'edit', :language => 'en')

      MailTemplateMailer.should_receive(:deliver_to_user)

      @rnd = generate_renderer(:mail_template_id => @email_template.id, :required_fields => [])
      renderer_post @rnd, :user => { :first_name => 'First' }

      @myself.errors.length.should == 0
      @myself.first_name.should == 'First'
    end

    it "should change user class id" do
      @rnd = generate_renderer(:user_class_id => 2, :modify_profile => 'modify', :required_fields => [])
      renderer_post @rnd, :user => { :first_name => 'First' }

      @myself.errors.length.should == 0
      @myself.first_name.should == 'First'
      @myself.user_class_id.should == 2
    end

  end

  describe "User Login Paragraph" do 
    def generate_renderer(data = {})
      default = {:login_type => 'email', :forward_login => 'no', :success_page => nil, :failure_page => nil}
      build_renderer('/page','/editor/auth/login',default.merge(data),{})
    end

    it "should be able to render the login paragraph for anonymous user" do
      @myself = EndUser.default_user
      @rnd = generate_renderer
      @rnd.should_receive(:myself).twice.and_return(@myself)
      @rnd.should_receive(:login_feature).and_return('')
      renderer_get @rnd
    end

    it "should be able to render the login paragraph for a real user" do
      mock_user
      @rnd = generate_renderer
      @rnd.should_receive(:myself).exactly(3).and_return(@myself)
      @rnd.should_receive(:login_feature).and_return('')
      renderer_get @rnd
    end

    it "should be able to logout with anonymous user" do
      @myself = EndUser.default_user
      @rnd = generate_renderer
      @rnd.should_receive(:process_logout)
      @rnd.should_receive(:redirect_paragraph).with(:page)
      @rnd.should_receive(:login_feature).exactly(0)
      renderer_get @rnd, :cms_logout => true
    end

    it "should be able to logout with real user" do
      mock_user
      @rnd = generate_renderer
      @rnd.should_receive(:myself).any_number_of_times.and_return(@myself)
      @rnd.should_receive(:redirect_paragraph).with(:page)
      @rnd.should_receive(:login_feature).exactly(0)
      renderer_get @rnd, :cms_logout => true
      @rnd.response.data[:user].should be_nil
    end

    it "should be able to login with email" do
      email = 'test@test.dev'
      password = 'myfakepassword'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :login_type => 'email'
      @rnd.should_receive(:process_login)
      @rnd.should_receive(:redirect_paragraph).with(:page)
      renderer_post @rnd, :cms_login => {:password => password, :login => email, :remember => 1}
    end

    it "should be able to login with username" do
      email = 'test@test.dev'
      username = 'testuser'
      password = 'myfakepassword'

      @user = EndUser.push_target(email)
      @user.username = username
      @user.registered = 1
      @user.activated = 1
      @user.password = password
      @user.save.should be_true

      EndUser.should_receive(:login_by_email).exactly(0)

      @rnd = generate_renderer :login_type => 'username'
      @rnd.should_receive(:redirect_paragraph).with(:page)
      renderer_post @rnd, :cms_login => {:password => password, :username => username, :remember => 1}
      @rnd.session[:user_id].should == @user.id
    end

    it "should be able to login with username or email" do
      email = 'test@test.dev'
      username = 'testuser'
      password = 'myfakepassword'

      @user = EndUser.push_target(email)
      @user.username = username
      @user.registered = 1
      @user.activated = 1
      @user.password = password
      @user.save.should be_true

      EndUser.should_receive(:login_by_email).once.and_return(nil)

      @rnd = generate_renderer :login_type => 'both'
      @rnd.should_receive(:process_login)
      @rnd.should_receive(:redirect_paragraph).with(:page)
      renderer_post @rnd, :cms_login => {:password => password, :login => username, :remember => 1}
    end

    it "should be able to login with email and forward user" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      lock_lockout = '/test'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :login_type => 'email', :forward_login => 'yes'
      @rnd.session[:lock_lockout] = lock_lockout
      @rnd.should_receive(:process_login)
      @rnd.should_receive(:redirect_paragraph).with(lock_lockout)
      renderer_post @rnd, :cms_login => {:password => password, :login => email, :remember => 1}
      @rnd.session[:lock_lockout].should be_nil
    end

    it "should be able to login with email and send user to success_page" do
      email = 'test@test.dev'
      password = 'myfakepassword'

      success_page = mock :id => 1, :node_path => '/success'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.password = password
      @user.save.should be_true

      SiteNode.should_receive(:find_by_id).once.and_return(success_page)

      @rnd = generate_renderer :login_type => 'email', :success_page => success_page.id
      @rnd.should_receive(:process_login)
      @rnd.should_receive(:redirect_paragraph).with(success_page.node_path)
      renderer_post @rnd, :cms_login => {:password => password, :login => email, :remember => 1}
    end

    it "should not be able to login if not registered" do
      email = 'test@test.dev'
      password = 'myfakepassword'

      @user = EndUser.push_target(email)
      @user.registered = 0
      @user.activated = 0
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :login_type => 'email'
      @rnd.should_receive(:process_login).exactly(0)
      @rnd.should_receive(:render_paragraph)
      renderer_post @rnd, :cms_login => {:password => password, :login => email, :remember => 1}
    end

    it "should not be able to login if registered but not activated" do
      email = 'test@test.dev'
      password = 'myfakepassword'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 0
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :login_type => 'email'
      @rnd.should_receive(:process_login).exactly(0)
      @rnd.should_receive(:render_paragraph)
      renderer_post @rnd, :cms_login => {:password => password, :login => email, :remember => 1}
    end

    it "should not be able to login if password is incorrect" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      incorrect_password = 'incorrect'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :login_type => 'email'
      @rnd.should_receive(:process_login).exactly(0)
      @rnd.should_receive(:render_paragraph)
      renderer_post @rnd, :cms_login => {:password => incorrect_password, :login => email, :remember => 1}
    end

    it "should not be able to login if password is incorrect and redirect to failure page" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      incorrect_password = 'incorrect'

      failure_page = mock :id => 1, :node_path => '/failure'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :login_type => 'email', :failure_page => failure_page.id
      @rnd.should_receive(:process_login).exactly(0)
      @rnd.should_receive(:redirect_paragraph).with(:site_node => failure_page.id)
      renderer_post @rnd, :cms_login => {:password => incorrect_password, :login => email, :remember => 1}
    end
  end

  describe "User Activation Paragraph" do 
    def generate_renderer(data = {})
      default = {:require_acceptance => false, :redirect_page_id => nil, :already_activated_redirect_page_url => nil, :login_after_activation => false}
      build_renderer('/page','/editor/auth/user_activation',default.merge(data),{})
    end

    it "should be able to render user_activation" do
      EndUser.should_receive(:find_by_activation_string).exactly(0)
      @rnd = generate_renderer
      @rnd.should_receive(:render_paragraph)
      renderer_get @rnd
    end

    it "should be able to activate a user from link" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      activation_string = 'activateme'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 0
      @user.activation_string = activation_string
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :require_acceptance => false
      @rnd.should_receive(:render_paragraph)
      renderer_get @rnd, :code => activation_string
      @user.reload
      @user.activated.should be_true
    end

    it "should not activate user without acceptance" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      activation_string = 'activateme'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 0
      @user.activation_string = activation_string
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :require_acceptance => true
      @rnd.should_receive(:render_paragraph)
      renderer_get @rnd, :code => activation_string
      @user.reload
      @user.activated.should be_false
    end

    it "should activate user when accepts" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      activation_string = 'activateme'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 0
      @user.activation_string = activation_string
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :require_acceptance => true
      @rnd.should_receive(:render_paragraph)
      renderer_post @rnd, :activate => {:code => activation_string, :accept => true}
      @user.reload
      @user.activated.should be_true
    end

    it "should not activate user when declines" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      activation_string = 'activateme'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 0
      @user.activation_string = activation_string
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :require_acceptance => true
      @rnd.should_receive(:render_paragraph)
      @rnd.should_receive(:process_login).exactly(0)
      renderer_post @rnd, :activate => {:code => activation_string, :accept => false}
      @user.reload
      @user.activated.should be_false
    end

    it "should activate user and login" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      activation_string = 'activateme'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 0
      @user.activation_string = activation_string
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :require_acceptance => true, :login_after_activation => true
      @rnd.should_receive(:render_paragraph)
      @rnd.should_receive(:process_login)
      renderer_post @rnd, :activate => {:code => activation_string, :accept => true}
      @user.reload
      @user.activated.should be_true
    end

    it "should activate user and redirect" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      activation_string = 'activateme'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 0
      @user.activation_string = activation_string
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :require_acceptance => true, :redirect_page_id => 1
      @rnd.should_receive(:redirect_paragraph)
      @rnd.should_receive(:process_login).exactly(0)
      renderer_post @rnd, :activate => {:code => activation_string, :accept => true}
      @user.reload
      @user.activated.should be_true
    end

    it "should redirect an already activated user" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      activation_string = 'activateme'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.activation_string = activation_string
      @user.password = password
      @user.save.should be_true

      @already_activated_redirect_page = SiteVersion.default.root_node.add_subpage('already_activated_redirect_page')
      @rnd = generate_renderer :require_acceptance => false, :already_activated_redirect_page_id => @already_activated_redirect_page.id
      @rnd.should_receive(:redirect_paragraph).with('/already_activated_redirect_page')
      renderer_get @rnd, :code => activation_string
    end
  end

  describe "Enter Vip Paragraph" do 
    def generate_renderer(data = {})
      default = {:success_page => nil, :already_registered_page => nil, :login_even_if_registered => false, :add_tags => ''}
      build_renderer('/page','/editor/auth/enter_vip',default.merge(data),{})
    end

    it "should render the enter_vip paragraph" do
      @rnd = generate_renderer
      @rnd.should_receive(:render_paragraph)
      renderer_get @rnd
    end

    it "should activate a vip user" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      vip_number = 'vip'

      @user = EndUser.push_target(email)
      @user.registered = 0
      @user.activated = 1
      @user.user_level = 1
      @user.vip_number = vip_number
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer
      @rnd.should_receive(:render_paragraph)
      @rnd.paragraph.should_receive(:run_triggered_actions).once.with(anything(), 'success', anything())
      renderer_post @rnd, :vip => {:number => vip_number}

      @rnd.session[:user_id].should == @user.id
    end

    it "should activate a vip user even if already registered" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      vip_number = 'vip'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.user_level = 1
      @user.vip_number = vip_number
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :login_even_if_registered => true
      @rnd.should_receive(:render_paragraph)
      @rnd.paragraph.should_receive(:run_triggered_actions).once.with(anything(), 'success', anything())
      renderer_post @rnd, :vip => {:number => vip_number}

      @rnd.session[:user_id].should == @user.id
    end

    it "should not activate a vip user if registered" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      vip_number = 'vip'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.user_level = 1
      @user.vip_number = vip_number
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :login_even_if_registered => false
      @rnd.should_receive(:render_paragraph)
      @rnd.paragraph.should_receive(:run_triggered_actions).once.with(anything(), 'repeat', anything())
      renderer_post @rnd, :vip => {:number => vip_number}

      @rnd.session[:user_id].should be_nil
    end

    it "should not activate a vip user with a bad vip number" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      vip_number = 'vip'
      bad_vip_number = 'bad_vip'

      @user = EndUser.push_target(email)
      @user.registered = 0
      @user.activated = 1
      @user.user_level = 1
      @user.vip_number = vip_number
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer
      @rnd.should_receive(:render_paragraph)
      @rnd.paragraph.should_receive(:run_triggered_actions).once.with(anything(), 'failure', anything())
      renderer_post @rnd, :vip => {:number => bad_vip_number}

      @rnd.session[:user_id].should be_nil
    end

    it "should activate a vip user and redirect to already registered page" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      vip_number = 'vip'

      page = mock :id => 1, :node_path => '/registered_vip'
      page2 = mock :id => 2, :node_path => '/success_vip'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.user_level = 1
      @user.vip_number = vip_number
      @user.password = password
      @user.save.should be_true

      SiteNode.should_receive(:find_by_id).once.with(page.id).and_return(page)
      @rnd = generate_renderer :login_even_if_registered => true, :already_registered_page => page.id, :success_page => page2.id
      @rnd.should_receive(:redirect_paragraph).once.with(page.node_path)
      @rnd.paragraph.should_receive(:run_triggered_actions).once.with(anything(), 'success', anything())
      renderer_post @rnd, :vip => {:number => vip_number}

      @rnd.session[:user_id].should == @user.id
    end

    it "should activate a vip user and redirect to success page" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      vip_number = 'vip'

      page = mock :id => 1, :node_path => '/registered_vip'
      page2 = mock :id => 2, :node_path => '/success_vip'

      @user = EndUser.push_target(email)
      @user.registered = 0
      @user.activated = 1
      @user.user_level = 1
      @user.vip_number = vip_number
      @user.password = password
      @user.save.should be_true

      SiteNode.should_receive(:find_by_id).once.with(page2.id).and_return(page2)
      @rnd = generate_renderer :login_even_if_registered => true, :already_registered_page => page.id, :success_page => page2.id
      @rnd.should_receive(:redirect_paragraph).once.with(page2.node_path)
      @rnd.paragraph.should_receive(:run_triggered_actions).once.with(anything(), 'success', anything())
      renderer_post @rnd, :vip => {:number => vip_number}

      @rnd.session[:user_id].should == @user.id
    end

    it "should activate a vip user and add tags" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      vip_number = 'vip_number'
      tags = 'vip'

      @user = EndUser.push_target(email)
      @user.registered = 0
      @user.activated = 1
      @user.user_level = 1
      @user.vip_number = vip_number
      @user.password = password
      @user.save.should be_true

      @rnd = generate_renderer :add_tags => tags
      @rnd.should_receive(:render_paragraph)
      @rnd.paragraph.should_receive(:run_triggered_actions).once.with(anything(), 'success', anything())
      renderer_post @rnd, :vip => {:number => vip_number}

      @user.reload
      @rnd.session[:user_id].should == @user.id
      @tag = Tag.find_by_name(tags)
      @tag.should_not be_nil
      @end_user_tag = EndUserTag.find_by_end_user_id_and_tag_id(@user.id, @tag.id)
      @end_user_tag.should_not be_nil
    end
  end

  describe "Missing Password Paragraph" do 
    def generate_renderer(data = {})
      @reset_page = SiteNode.find_by_title('reset') || SiteVersion.default.root_node.add_subpage('reset')
      @email_template = MailTemplate.find_by_name('reset') || MailTemplate.create(:subject => 'Reset Password', :name => 'reset', :language => 'en')
      default = {:reset_password_page => @reset_page.id, :email_template => @email_template.id}
      build_renderer('/page','/editor/auth/missing_password',default.merge(data),{})
    end

    it "should render missing password paragraph" do
      @rnd = generate_renderer
      @reset_page.id.should_not be_nil
      @email_template.id.should_not be_nil
      @rnd.should_receive(:render_paragraph)
      renderer_get @rnd
    end

    it "should be able to send missing password email" do
      email = 'test@test.dev'
      password = 'myfakepassword'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.password = password
      @user.save.should be_true

      @user.verification_string.should be_nil
      @rnd = generate_renderer
      MailTemplateMailer.should_receive(:deliver_to_user)
      @rnd.should_receive(:redirect_paragraph).with(:page)
      renderer_post @rnd, :missing_password => {:email => email}

      @user.reload
      @user.verification_string.should_not be_nil
    end

    it "should not send missing password email" do
      email = 'test@test.dev'
      password = 'myfakepassword'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.password = password
      @user.save.should be_true

      @user.verification_string.should be_nil
      @rnd = generate_renderer
      MailTemplateMailer.should_receive(:deliver_to_user).exactly(0)
      @rnd.should_receive(:redirect_paragraph).with(:page)
      renderer_post @rnd, :missing_password => {:email => 'bademail@test.dev'}

      @user.reload
      @user.verification_string.should be_nil
    end

    it "should be able to login in user through verification" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      verification_string = 'verifyme'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.password = password
      @user.verification_string = verification_string
      @user.save.should be_true

      @rnd = generate_renderer
      MailTemplateMailer.should_receive(:deliver_to_user).exactly(0)
      @rnd.should_receive(:redirect_paragraph)
      renderer_post @rnd, :verification => verification_string

      @user.reload
      @user.verification_string.should be_nil
    end

    it "should not login in user with an invalid verification" do
      email = 'test@test.dev'
      password = 'myfakepassword'
      verification_string = 'verifyme'

      @user = EndUser.push_target(email)
      @user.registered = 1
      @user.activated = 1
      @user.password = password
      @user.verification_string = verification_string
      @user.save.should be_true

      @rnd = generate_renderer
      MailTemplateMailer.should_receive(:deliver_to_user).exactly(0)
      @rnd.should_receive(:render_paragraph)
      renderer_post @rnd, :verification => 'bedverificationstring'

      @user.reload
      @user.verification_string.should_not be_nil
    end
  end

  describe "Splash Paragraph" do
    def generate_renderer(data = {})
      @splash_page = SiteNode.find_by_title('splash') || SiteVersion.default.root_node.add_subpage('splash')
      default = {:splash_page_id => @splash_page.id}
      build_renderer('/page','/editor/auth/splash',default.merge(data),{})
    end

    it "should render the splash paragraph" do
      @rnd = generate_renderer
      @cookies = {}
      @rnd.should_receive(:cookies).any_number_of_times.and_return(@cookies)
      @rnd.should_receive(:redirect_paragraph).with(@splash_page.node_path)
      renderer_get @rnd
      @cookies[:splash][:value].should == 'set'
    end

    it "should render nothing if already seen splash page" do
      @rnd = generate_renderer
      @cookies = {:splash => 'set'}
      @rnd.should_receive(:cookies).any_number_of_times.and_return(@cookies)
      @rnd.should_receive(:render_paragraph).with(:nothing => true)
      renderer_get @rnd
    end

    it "should set cookie and render nothing if no_splash is sent" do
      @rnd = generate_renderer
      @cookies = {}
      @rnd.should_receive(:cookies).any_number_of_times.and_return(@cookies)
      @rnd.should_receive(:render_paragraph).with(:nothing => true)
      renderer_get @rnd, :no_splash => true
      @cookies[:splash][:value].should == 'set'
    end
  end

  describe "Email List Paragraph" do
    def generate_renderer(data = {})
      @subscription ||= UserSubscription.create :name => 'Test'
      @destination_page = SiteNode.find_by_title('destiny') || SiteVersion.default.root_node.add_subpage('destiny')
      default = {:user_subscription_id => @subscription.id, :tags => nil, :zip => 'optional', :first_name => 'off',
	         :last_name => 'off',:destination_page_id => @destination_page.id, :user_source => nil,
                 :success_message => 'Thank you, your email has been added to our list',
                 :partial_post => 'yes'}
      build_renderer('/page','/editor/auth/email_list',default.merge(data),{})
    end

    it "should render the email list paragraph" do
      @rnd = generate_renderer
      @rnd.should_receive(:render_paragraph)
      renderer_get @rnd
    end

    it "should signup for a email list" do
      email_list_signup_info = { :email => 'test@test.dev',
	                         :zip => '55555'
                               }

      @rnd = generate_renderer
      @rnd.should_receive(:redirect_paragraph)

      assert_difference 'UserSubscriptionEntry.count', 1 do
	renderer_post @rnd, :email_list_signup => email_list_signup_info
      end

      user = EndUser.find_by_email('test@test.dev')
      user.should_not be_nil
      user.user_level.should == 3
    end

    it "should not signup for a email list if a missing field is required" do
      email_list_signup_info = { :email => 'test@test.dev',
	                         :zip => ''
                               }

      @rnd = generate_renderer :zip => 'required'
      @rnd.should_receive(:render_paragraph)

      assert_difference 'UserSubscriptionEntry.count', 0 do
	renderer_post @rnd, :email_list_signup => email_list_signup_info
      end

      user = EndUser.find_by_email('test@test.dev')
      user.should be_nil

      email_list_signup_info = { :email => 'test@test.dev',
	                         :first_name => ''
                               }

      @rnd = generate_renderer :first_name => 'required'
      @rnd.should_receive(:render_paragraph)

      assert_difference 'UserSubscriptionEntry.count', 0 do
	renderer_post @rnd, :email_list_signup => email_list_signup_info
      end

      email_list_signup_info = { :email => 'test@test.dev',
	                         :last_name => ''
                               }

      @rnd = generate_renderer :last_name => 'required'
      @rnd.should_receive(:render_paragraph)

      assert_difference 'UserSubscriptionEntry.count', 0 do
	renderer_post @rnd, :email_list_signup => email_list_signup_info
      end
    end

    it "should signup for a email list if a missing field is optional" do
      email_list_signup_info = { :email => 'test@test.dev',
	                         :zip => ''
                               }

      @rnd = generate_renderer :zip => 'optional'
      @rnd.should_receive(:redirect_paragraph)

      assert_difference 'UserSubscriptionEntry.count', 1 do
	renderer_post @rnd, :email_list_signup => email_list_signup_info
      end
    end

    it "should add an entry for user subscription on a partial post even if missing data" do
      email_list_signup_info = { :email => 'test@test.dev',
	                         :zip => ''
                               }

      @rnd = generate_renderer :zip => 'required', :partial_post => 'yes'
      @rnd.should_receive(:render_paragraph)

      assert_difference 'UserSubscriptionEntry.count', 1 do
	renderer_post @rnd, :partial_post => true, :email_list_signup => email_list_signup_info
      end

      user = EndUser.find_by_email('test@test.dev')
      user.should_not be_nil
      user.user_level.should == 3
    end

    it "should not add an entry for user subscription when not allowing for partial_post and missing data" do
      email_list_signup_info = { :email => 'test@test.dev',
	                         :zip => ''
                               }

      @rnd = generate_renderer :zip => 'required', :partial_post => 'no'
      @rnd.should_receive(:render_paragraph)

      assert_difference 'UserSubscriptionEntry.count', 0 do
	renderer_post @rnd, :partial_post => true, :email_list_signup => email_list_signup_info
      end
    end

    it "should signup for a email list and tag user" do
      email_list_signup_info = { :email => 'test@test.dev',
	                         :zip => '55555'
                               }

      @rnd = generate_renderer :tags => 'email_list'
      @rnd.should_receive(:redirect_paragraph)

      assert_difference 'UserSubscriptionEntry.count', 1 do
	renderer_post @rnd, :email_list_signup => email_list_signup_info
      end

      @tag = Tag.find_by_name('email_list')
      @tag.should_not be_nil
      @user = EndUser.find_by_email('test@test.dev')
      @user.should_not be_nil
      @end_user_tag = EndUserTag.find_by_end_user_id_and_tag_id(@user.id, @tag.id)
      @end_user_tag.should_not be_nil
    end
  end

  describe "View Account Paragraph" do
    def generate_renderer(data = {})
      build_renderer('/page','/editor/auth/view_account',data,{})
    end

    it "should render view account paragraph" do
      @rnd = generate_renderer
      @rnd.should_receive(:render_paragraph)
      renderer_get @rnd
    end
  end
end

