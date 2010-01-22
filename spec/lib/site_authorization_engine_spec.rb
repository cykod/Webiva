require File.dirname(__FILE__) + "/../spec_helper"

describe SiteAuthorizationEngine, :type => :controller do
  controller_name :page

  reset_domain_tables :end_users, :site_versions, :page_revisions, :site_nodes, :site_node_modifiers, :page_paragraphs, :site_templates, :roles, :user_roles


  describe "Lock Access" do
    before(:each) do
      

      @site_template = SiteTemplate.create(:name => 'Test Template',:template_html => '<div class="container"><cms:zone name="main"/></div>')
      
      @page = SiteVersion.default.root_node.add_subpage('test_page')
      @paragraph1 =  @page.live_revisions[0].page_paragraphs.create(:display_type => 'html',:display_body => "Test Code",:zone_idx => 1, :position => 2)


      @redirect_page = SiteVersion.default.root_node.add_subpage('redirect_page')

      @lock = @page.add_modifier('lock')
      @lock.modifier_data = SiteNodeModifier::LockModifierOptions.new(
                                                                      :access_control => 'lock',
                                                                      :options => [],
                                                                      :redirect => @redirect_page.id
                                                                      ).to_hash
      @lock.save
    end

    it "should redirect a user we don't have access to a lock" do
      @myself = EndUser.push_target('svend@karslon.com')

      engine = SiteNodeEngine.new(@page)
      @output = engine.run(controller,@myself)
      @output.class.should == SiteNodeEngine::RedirectOutput
      @output.redirect.should == "/redirect_page"
    end

    it "should render if the user does have access to a lock" do
      @myself = EndUser.push_target('svend@karslon.com')
      @myself.user_class.has_role('access',@lock)

      @lock.user_roles_display('access').should == ["Profile: Default"]

      engine = SiteNodeEngine.new(@page)
      @output = engine.run(controller,@myself)
      @output.class.should == SiteNodeEngine::PageOutput
    end

  end

  describe "General role usage" do
    
    it "should deny access by default" do
      @myself = EndUser.push_target('svend@karslon.com',:user_class_id => 3)

      @myself.has_role?(:editor_website).should be_false
    end
    
    it "shouldn't allow users to upgrade to admin users" do
      @myself = EndUser.push_target('svend@karslon.com',:user_class_id => 2)

      @myself.has_role?(:editor_website).should be_false
    end

    it "should allow editor users access it the role has been added" do
      UserClass.domain_user_class.has_role(:editor_website)
      @myself = EndUser.push_target('svend@karslon.com',:user_class_id => 3)

      @myself.has_role?(:editor_website).should be_true
    end

    it "should be able to check multiple roles" do
      UserClass.domain_user_class.has_role(:editor_website)
      @myself = EndUser.push_target('svend@karslon.com',:user_class_id => 3)
      
      @myself.has_any_role?(Role.expand_roles([:editor_website,:editor_structure])).should be_true
      @myself.has_all_roles?(Role.expand_roles([:editor_website,:editor_structure])).should be_false
    end

    it "should be able to remove a role roles" do
      UserClass.domain_user_class.has_role(:editor_website)
      UserClass.domain_user_class.has_no_role(:editor_website)
      @myself = EndUser.push_target('svend@karslon.com',:user_class_id => 3)
      
      @myself.has_role?(:editor_website).should be_false
    end
    
    it "should be able to test roles on user class" do
      UserClass.domain_user_class.has_role(:editor_website)
      
    end

    
  end

  describe "Controller Permit Usage" do

    it "should prevent users from accessing controller they don't have the role for" do
      @myself = EndUser.push_target('svend@karslon.com',:user_class_id => 3)

      # We know the 
      ctrl = StructureController.new
      ctrl.should_receive(:myself).at_least(:once).and_return(@myself)
      ctrl.should_receive(:store_return_location).and_return(true)
      ctrl.should_receive(:redirect_to).and_return(true)

      ctrl.send(:permit,:editor_website).should be_false
      ctrl.send(:permit?,:editor_website).should be_false

      
    end

  end

end

