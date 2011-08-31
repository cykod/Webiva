require File.dirname(__FILE__) + "/../spec_helper"

describe SiteVersion do
  
  reset_domain_tables :site_nodes, :content_types, :content_nodes,  :site_versions, :site_node_modifiers, :page_revisions, :page_paragraphs

  it "should create a default site version and a home page" do
    SiteVersion.count.should == 0
    version = SiteVersion.default
    SiteVersion.count.should == 1

    SiteNode.count.should == 0
    root = version.root_node
    SiteNode.count.should == 2
    root.children[0].title.should == ''
    root.children[0].active_revisions[0].menu_title.should == 'Home'
  end

  it "should be able to make a copy for a site version" do
    @members_wizard = Wizards::MembersSetup.new :add_to_id => SiteVersion.current.root.id
    @members_wizard.run_wizard
    SiteVersion.current.reload
    @members_node = SiteVersion.current.site_nodes.find_by_node_path('/members')
    @members_node.should_not be_nil
    @login_node = SiteVersion.current.site_nodes.find_by_node_path('/login')
    @login_node.should_not be_nil
    @login_para = @login_node.live_revisions.first.page_paragraphs.first :conditions => {:display_type => 'login', :display_module => '/editor/auth'}
    @login_para.should_not be_nil
    @login_para.paragraph_options.success_page.should == @members_node.id
      
    @version2 = SiteVersion.current.copy "test"
    @members_node2 = @version2.site_nodes.find_by_node_path('/members')
    @members_node2.should_not be_nil
    @login_node2 = @version2.site_nodes.find_by_node_path('/login')
    @login_node2.should_not be_nil
    @login_para2 = @login_node2.live_revisions.first.page_paragraphs.first :conditions => {:display_type => 'login', :display_module => '/editor/auth'}
    @login_para2.should_not be_nil
    @login_para2.paragraph_options.success_page.should == @members_node2.id
    @members_node2.id.should_not == @members_node.id
  end
end
