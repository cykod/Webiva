



require File.dirname(__FILE__) + "/../spec_helper"

describe SiteVersion do
  
  reset_domain_tables :site_nodes, :content_types, :content_nodes,  :site_versions, :site_node_modifiers

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

end
