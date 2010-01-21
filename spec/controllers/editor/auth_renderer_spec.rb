require File.dirname(__FILE__) + "/../../spec_helper"


describe Editor::AuthRenderer, :type => :controller do
  controller_name :page
  
  integrate_views


  describe "User Register Paragraph" do 
    def generate_renderer(data = {})
      # Set a user class b/c we need one
      default = { :user_class_id => UserClass.default_user_class_id }
      build_renderer('/page','/editor/auth/user_register',default.merge(data),{})
    end
    
    reset_domain_tables :end_users,:end_user_addresses, :tags, :end_user_tags
    
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
        @rnd = generate_renderer(:address_required_fields => ['state'])
      renderer_post @rnd, :user => { :email => "test@webiva.com", :password => "test", :password_confirmation => "test" }, :address => { :address => '123 Elm St',:city => 'Boston' }

      EndUser.count.should == 0
    end

    it "should save if all required address fields are there" do
        @rnd = generate_renderer(:address_required_fields => ['state','city','state'])
      renderer_post @rnd, :user => { :email => "test@webiva.com", :password => "test", :password_confirmation => "test" }, :address => { :address => '123 Elm St',:city => 'Boston', :state => 'MA' }

      EndUser.count.should == 1
      usr = EndUser.find(:first)
      usr.address.address.should == '123 Elm St'
      usr.address.city.should == 'Boston'
      usr.address.state.should == 'MA'
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
      usr.tag_names.should == ['test1','test2']
    end

    it "should be able to set the user source" do
      @rnd = generate_renderer(:registration_type => 'info',:source =>'tester_source')
      renderer_post @rnd, :user => { :email => "test@webiva.com" }
      EndUser.count.should == 1
      usr = EndUser.find(:first)
      usr.lead_source.should =='tester_source'
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
      @user.activation_string.should be_nil
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
      @user.activation_string.should == activation_string
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
      @user.activation_string.should be_nil
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
      @user.activation_string.should == activation_string
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
      @user.activation_string.should be_nil
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
      @user.activation_string.should be_nil
      @user.activated.should be_true
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
end
  
