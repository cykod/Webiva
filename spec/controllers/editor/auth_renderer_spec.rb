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
end
  
