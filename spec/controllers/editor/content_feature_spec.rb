require File.dirname(__FILE__) + "/../../spec_helper"

describe Editor::ContentFeature, :type => :view do

  reset_domain_tables :site_nodes, :content_nodes, :site_versions, :content_types

  before(:each) do
    @feature = build_feature('/editor/content_feature')
  end

  it "should render recent content" do
    SiteVersion.default.root_node.add_subpage('home')
    SiteVersion.default.root_node.add_subpage('about-us')
    SiteVersion.default.root_node.add_subpage('contact')

    @type = ContentType.create :component => 'editor', :content_name => 'Static Pages', :content_type => 'SiteNode', :title_field => 'name', :url_field => 'id', :search_results => 1, :editable => 0, :created_at => Time.now, :updated_at => Time.now
    @type.id.should_not be_nil
    ContentNode.update_all :content_type_id => @type.id

    @nodes = ContentNode.find(:all, :limit => 10)

    @output = @feature.recent_content_feature(:nodes => @nodes)
    @output.should include('home')
    @output.should include('about-us')
    @output.should include('contact')
    @output.should include('Static Pages')
  end
end
