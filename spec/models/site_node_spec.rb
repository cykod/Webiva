require File.dirname(__FILE__) + "/../spec_helper"

describe SiteNode do
  
  reset_domain_tables :site_nodes, :content_types, :content_nodes,  :site_versions, :site_node_modifiers, :end_user
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

  it "should be able to add modifiers to nodes" do
    nd = @version.root_node.add_subpage('about')

    assert_difference('SiteNodeModifier.count', 2) do
      nd.add_modifier('framework')
      nd.add_modifier('template')
    end
  end

  it "should be able to get a menu of nodes" do
    news = @version.root_node.add_subpage('news')
    group = @version.root_node.add_subpage('group', 'G')
    page1 = group.add_subpage('page1')
    page2 = group.add_subpage('page2')
    page3 = group.add_subpage('page3')

    @version.root_node.menu.should == [@version.root_node]
    news.menu.should == [news]
    group.menu.should == [page1, page2, page3]
  end

  it "should be able to get the nested pages" do
    news = @version.root_node.add_subpage('news')
    group = news.add_subpage('group', 'G')
    page1 = group.add_subpage('page1')
    page2 = group.add_subpage('page2')
    page3 = group.add_subpage('page3')
    about = @version.root_node.add_subpage('about')
    home = @version.site_nodes.with_type('P').find_by_title('')

    @version.root_node.child_cache.should == []

    @version.root_node.reload
    @version.root_node.nested_pages [group.id]

    @version.root_node.child_cache.should == [home, news, about]
    @version.root_node.child_cache[0].should == home
    @version.root_node.child_cache[0].child_cache.should == []
    @version.root_node.child_cache[1].should == news
    @version.root_node.child_cache[1].child_cache.should == [group]
    @version.root_node.child_cache[2].should == about
    @version.root_node.child_cache[2].child_cache.should == []

    @version.root_node.child_cache[1].child_cache[0].should == group
    @version.root_node.child_cache[1].child_cache[0].child_cache.should == [page1, page2, page3]
    @version.root_node.child_cache[1].child_cache[0].closed.should be_true

    SiteNode.find_page(group.id).should be_nil
    SiteNode.find_page(about.id).should == about

    SiteNode.node_path(@version.root_node.id).should == 'Domain'
    SiteNode.node_path(group.id).should == '/'
    SiteNode.node_path(about.id).should == '/about'
    SiteNode.node_path(-1, '/missing').should == '/missing'
  end

  it "should be able to create node paths" do
    SiteNode.generate_node_path(' Page   (1)   ...').should == 'page-1'
    SiteNode.generate_node_path(' _Page-_   (1)   ...').should == '-page-1'
  end

  it "should be able to create new revisions" do
    news = @version.root_node.add_subpage('news')
    rv = news.active_revision('en')
    rv.title = 'My News'
    rv.save

    news.new_revision do |rv|
      rv.title = 'Changed News Title'
    end

    news.reload
    news.active_revision('en').title.should == 'Changed News Title'
    news.name.should == 'Changed News Title'
    news.content_description('en').should == 'Site Page - /news'
    news.page_type.should == 'page'
    SiteNode.send(:content_admin_url, news.id).should == {:controller => '/edit', :action => 'page', :path => ['page', news.id]}
    news.send(:content_node_body, 'es').should be_nil
  end

  it "should be able to set group node options" do
    news = @version.root_node.add_subpage('news')
    group = news.add_subpage('group', 'G')

    news.node_options.to_hash.should == {}

    group.node_options.closed.should be_false

    group.set_node_options :closed => true
 
    group = SiteNode.find_by_id(group.id)

    group.node_options.closed.should be_true
  end

  it "should be able to fetch all paragraphs from frameworks" do
    para1 = nil
    para2 = nil
    news = @version.root_node.add_subpage('news')
    framework = news.add_modifier('framework') do |md|
      md.new_revision do |rv|
        para1 = rv.push_paragraph '/editor/auth', 'login', {}, :zone => 3
      end
    end

    template = news.add_modifier('template')

    @version.root_node.add_modifier('framework') do |md|
      md.new_revision do |rv|
        para2 = rv.push_paragraph '/editor/auth', 'login', {}, :zone => 1
      end
    end

    template = @version.root_node.add_modifier('template')
    template.modifier_data[:clear_frameworks] = 'yes'
    template.save

    news.reload
    news.full_framework_paragraphs('en').should == [para2, para1]
  end
end
