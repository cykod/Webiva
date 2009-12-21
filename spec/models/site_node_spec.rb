

require File.dirname(__FILE__) + "/../spec_helper"

describe SiteNode do
  
  reset_domain_tables :site_nodes, :content_types, :content_nodes,  :site_versions, :site_node_modifiers

  before(:each) do
    @version = SiteVersion.create(:name => 'Default')
  end

  it "should be able to create the SiteNode content type" do
    ContentType.count.should == 0
    Editor::AdminController.content_node_type_generate
    
    ct = ContentType.find_by_content_type('SiteNode')
    
    ct.content_name.should == 'Static Pages'
    ct.component.should == 'editor'
  end
  
  it "should create and destroy a content_node when created" do
    Editor::AdminController.content_node_type_generate
    
    # Should create a site node on create
    lambda {
     @page_node = SiteNode.create(:node_type => 'P', :title => 'test_page',:site_version_id => @version.id)
    }.should change { ContentNode.count }.by(1)
    
    # And delete it on delete
    lambda {
     @page_node.destroy
    }.should change { ContentNode.count }.by(-1)
    
  end

  it "should update a content node when a new revision is made real" do
    Editor::AdminController.content_node_type_generate
    
    # Should create a site node on create
    lambda {
     @page_node = SiteNode.create(:node_type => 'P', :title => 'test_page',:site_version_id => @version.id)
    }.should change { ContentNode.count }.by(1)

    # Cheat to create make sure the time is updated
    ContentNode.update_all(:updated_at => Time.now - 10.minutes)
    @page_node.reload
    node_updated_at = @page_node.content_node.updated_at

    rev = @page_node.active_revisions[0].create_temporary
    rev.make_real

    @page_node.reload
    @page_node.content_node.updated_at.should_not == node_updated_at
  end

  it "should be able to create a new version and get a root node" do

    @version.should be_valid

    # Should be able to get the root node which automatically
    # generates a home page
    nd = @version.root_node
    nd.should be_valid

    nd.parent_id.should be_nil
    nd.children.length.should == 1
  end

end
