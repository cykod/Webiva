require File.dirname(__FILE__) + "/../spec_helper"

describe StructureController do
  integrate_views


  reset_domain_tables :site_versions, :site_nodes, :site_node_modifiers, :page_revisions, :page_paragraphs
  

  before(:each) do
    mock_editor

    @version = SiteVersion.create(:name => 'Default')
    # Get the home page
    @home_page = @version.root_node.children[0]
  end


  it "should be able to add in a page" do

    put(:add_node,
        { :parent_id => @version.root_node, :node_type => 'P',
          :title => 'test_page' })

    controller.should render_template('structure/_path')

    nd = @version.root_node
    nd.reload

    # Should have the home page and the new page
    nd.children.length.should == 2

    nd.children[1].title.should == 'test_page'

    
    # Make sure we're in the right site version
    nd.children[1].site_version.should == @version
  end

  it "should be able to add in a group" do

    put(:add_node,
        { :parent_id => @version.root_node, :node_type => 'G',
          :title => 'Test Group' })

    controller.should render_template('structure/_path')

    nd = @version.root_node
    nd.reload

    # Should have the home page and the new page
    nd.children.length.should == 2

    nd.children[1].title.should == 'Test Group'

    
    # Make sure we're in the right site version
    nd.children[1].site_version.should == @version
  end



  describe "Should be able to adjust nodes" do

    before(:each) do

      @home_page = @version.root_node.children[0]

      @sp1 =@home_page.add_subpage('subpage_1')
      @sp2 =@home_page.add_subpage('subpage_2')
      @sp3 =@home_page.add_subpage('subpage_3')
    end
    
    it "should be able to move a page to the top of a list" do
      @home_page.children.should == [ @sp1, @sp2, @sp3 ]
      put(:adjust_node,  { :node_id => @sp3.id, :adjustment => '-2', :previous_id => nil })
      @home_page.reload
      @home_page.children.should == [ @sp3, @sp1, @sp2 ]
    end

    it "should be able to move a page to the middle of a list" do
      @home_page.children.should == [ @sp1, @sp2, @sp3 ]
      put(:adjust_node,  { :node_id => @sp1.id, :adjustment => '1', :previous_id => @sp2.id })
      @home_page.reload
      @home_page.children.should == [ @sp2, @sp1, @sp3 ]
    end

    it "should be able to move a page to the bottom of a list" do
      @home_page.children.should == [ @sp1, @sp2, @sp3 ]
      put(:adjust_node,  { :node_id => @sp1.id, :adjustment => '2', :previous_id => @sp3.id })
      @home_page.reload
      @home_page.children.should == [ @sp2, @sp3, @sp1 ]
    end

    it "should be able to move a node" do
      @home_page.children.should == [ @sp1, @sp2, @sp3 ]
      put(:move_node,  { :node_id => @sp1.id, :parent_id => @sp3.id.to_s })
      @home_page.reload
      @home_page.children.should == [ @sp2, @sp3 ]

      @sp3.reload
      @sp3.children.should == [ @sp1 ]
    end

    it "should be able to duplicate a node" do
      put(:copy_node, { :node_id => @sp1, :parent_id => @home_page })
      @home_page.reload
      @home_page.children.length.should == 4
      @home_page.children[3].title.should == (@home_page.children[0].title + "_copy")
    end
  end


  describe "Modifier Handling" do

   
    it "should be able to add a modifier" do

      # Should just have the page modifier
      @home_page.site_node_modifiers.length.should == 1
      
      put(:add_modifier, { :parent_id => @home_page.id, :modifier_type => 'template' })

      @home_page.reload

      # Should have the new modifier now
      @home_page.site_node_modifiers.length.should == 2
        
      controller.should render_template('structure/_site_node_modifier')
    end

    it "should be able to adjust a modifier" do
      md = @home_page.add_modifier('template')

      @home_page.site_node_modifiers.length.should == 2
      @home_page.site_node_modifiers[0].should == md

      put(:adjust_modifier, { :mod_id => md.id, :adjustment => 1 })

      @home_page.reload
      @home_page.site_node_modifiers.length.should == 2
      # Should be at the end now
      @home_page.site_node_modifiers[1].should == md
    end

    it "should be able to move a modifier" do
      @sp1 = @home_page.add_subpage('subpage_1')

      md = @home_page.add_modifier('template')

      @home_page.site_node_modifiers.length.should == 2
      @home_page.site_node_modifiers[0].should == md

      put(:move_modifier, { :modifier_id => md.id, :node_id => @sp1.id })

      @home_page.reload
      @home_page.site_node_modifiers.length.should == 1

      @sp1.site_node_modifiers.length.should == 2
      @sp1.site_node_modifiers[0].should == md
      
    end
    
    it "should be able to remove a modifier"  do
      md = @home_page.add_modifier('template')
      @home_page.site_node_modifiers.length.should == 2

      put(:remove_modifier, { :modifier_id => md.id })

      @home_page.reload
      @home_page.site_node_modifiers.length.should == 1
    end

  end

  describe "Node Information" do

    it "should be able to edit a node's title" do

      @sp1 = @home_page.add_subpage('subpager')

      put(:edit_node_title, { :node_id => @sp1.id, :title => 'the_subpager' })

      @sp1.reload

      @sp1.title.should == 'the_subpager'
      
    end

    it "should be able to update the revision" do
      @sp1 = @home_page.add_subpage('subpager')

      @rev = @sp1.active_revision('en')

      @rev.title.should be_blank

      put(:update_revision, { :revision_id => @rev.id, :revision_edit => { :title => 'New Revision Title' }})

      @rev.reload
      @rev.title.should == 'New Revision Title'
    end

  end
  
  describe "Element Information" do

    it "should be able to display a page"  do
      @sp1 = @home_page.add_subpage('subpager')

      put('element_info',{ :node_type => 'node', :node_id => @sp1.id })

      controller.should render_template('structure/_page_element_info')
      
    end
  end


  describe "Index Page" do
    it "should render the index page" do
      get 'index'
    end

    it "should render the index page" do
      get 'index', :archived => 'show'
    end

    it "should render the index page" do
      get 'index', :modules => 'show'
    end

    it "should render the index page" do
      get 'index', :modifiers => 'show'
    end
  end

  describe "Wizards" do
    it "should render the wizards page" do
      get 'wizards', :version => 1
    end

    it "should render the simple site wizard" do
      get 'wizard', :path => ['wizards', 'simple_site'], :version => 1
      response.should render_template('structure/wizard')
    end

    it "should not run the wizard" do
      post 'wizard', :path => ['wizards', 'simple_site'], :version => 1, :wizard => {}
      response.should redirect_to(:controller => '/structure', :action => 'wizards', :version => 1)
    end

    it "should not run the wizard" do
      post 'wizard', :path => ['wizards', 'simple_site'], :version => 1, :wizard => {}, :commit => 1
      response.should render_template('structure/wizard')
    end

    it "should run the wizard" do
      post 'wizard', :path => ['wizards', 'simple_site'], :version => 1, :wizard => {:name => 'Test.dev', :pages => ['Home', 'About', 'News']}, :commit => 1
      response.should redirect_to(:controller => '/structure', :version => 1)
    end
  end

  describe 'Versions' do
    it "should be able to render site_version" do
      get 'site_version', :site_version => 1
    end

    it "should be able to create site_version" do
      assert_difference 'SiteVersion.count', 1 do
        post 'site_version', :version => {:name => 'New Version'}
      end
    end
  end

  describe 'Multi Page Editor' do
    # Test all the permutations of an active table
    it "should handle site nodes list" do
      controller.should handle_active_table(:site_nodes_table) do |args|
        post 'display_site_nodes_table', {:path => [SiteVersion.current.id]}.merge(args)
      end
    end

    it "should be able to render edit_page_revision" do
      @rev = @home_page.active_revision('en')
      get 'edit_page_revision', :path => [@home_page.id, @rev.id]
    end

    it "should be able to create site_version" do
      @rev = @home_page.active_revision('en')
      post 'edit_page_revision', :path => [@home_page.id, @rev.id], :revision => {:title => 'My New Title'}

      @rev.reload
      @rev.title.should == 'My New Title'
    end
  end
end
