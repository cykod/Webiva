require File.dirname(__FILE__) + "/../../spec_helper"


describe Editor::MenuRenderer, :type => :controller do
  controller_name :page
  
  integrate_views

  reset_domain_tables :end_users, :site_versions, :page_revisions, :site_nodes, :page_paragraphs

  def generate_page_renderer(paragraph, options={}, inputs={})
    @rnd = build_renderer('/page', "/editor/menu/#{paragraph}", options, inputs)
  end

  def create_mock_node(children=[], name=nil)
    @node_id = (@node_id || 0) + 10
    name = name || "test_#{@name}"
    mock :title => name, :node_type => 'P', :live_revisions => [0], :node_path => "/#{name}", :id => @node_id, :children => children
  end

  it "should render a menu" do
    mock_user

    test_node = mock :title => 'test', :node_type => 'P', :live_revisions => [0], :node_path => '/test', :id => 10
    page_revision = mock :language => 'en'

    link1 = {:title => 'Test', :dest => 'url', :url => '/test.html'}
    link2 = {:title => 'Test2', :dest => 'url', :url => '/test2.html'}
    link3 = {:title => 'Test3', :dest => 'url', :url => '/test3.html'}
    link4 = {:title => 'Test4', :dest => 'page', :url => test_node.id}
    menu = {:menu => [link1.merge(:menu => [link2.merge(:menu => [link3])]), link4]}

    @rnd = generate_page_renderer('menu', menu)

    @rnd.paragraph.should_receive(:page_revision).and_return(page_revision)
    SiteNode.should_receive(:find_by_id).once.and_return(test_node)

    @output = renderer_get @rnd
    @output.status.should == '200 OK'
  end

  it "should renderer an automenu with subpages" do
    mock_user

    page_revision = mock :language => 'en', :menu_title => '', :title => '', :meta_description => ''

    test2 = create_mock_node
    test3 = create_mock_node
    test1 = create_mock_node [test2, test3]
    root_node = mock :title => nil, :node_type => 'R', :live_revisions => [0], :node_path => nil, :id => 1, :children => [test1]

    options = {:root_page => root_node.id, :levels => 2, :excluded => [], :included => []}

    @rnd = generate_page_renderer('automenu', options)
    @rnd.paragraph.should_receive(:language).any_number_of_times.and_return('en')

    SiteNode.should_receive(:find_by_id).with(root_node.id).and_return(root_node)

    root_node.children.each do |test_node|
      test_node.should_receive(:menu).and_return([test_node])
      test_node.should_receive(:active_revision).and_return(page_revision)
      test_node.should_receive(:is_a?).with(SiteNode).and_return(test_node)
    end

    test1.children.each do |test_node|
      test_node.should_receive(:menu).and_return([test_node])
      test_node.should_receive(:active_revision).and_return(page_revision)
    end

    @output = renderer_get @rnd
    @output.status.should == '200 OK'
  end

  it "should renderer an automenu without subpages" do
    mock_user

    page_revision = mock :language => 'en', :menu_title => '', :title => '', :meta_description => ''

    test2 = create_mock_node
    test3 = create_mock_node
    test1 = create_mock_node [test2, test3]
    root_node = mock :title => nil, :node_type => 'R', :live_revisions => [0], :node_path => nil, :id => 1, :children => [test1]

    options = {:root_page => root_node.id, :levels => 1, :excluded => [], :included => []}

    @rnd = generate_page_renderer('automenu', options)
    @rnd.paragraph.should_receive(:language).any_number_of_times.and_return('en')

    SiteNode.should_receive(:find_by_id).with(root_node.id).and_return(root_node)

    root_node.children.each do |test_node|
      test_node.should_receive(:menu).and_return([test_node])
      test_node.should_receive(:active_revision).and_return(page_revision)
    end

    @output = renderer_get @rnd
    @output.status.should == '200 OK'
  end

  it "should renderer an automenu without a page" do
    mock_user

    page_revision = mock :language => 'en', :menu_title => '', :title => '', :meta_description => ''

    test2 = create_mock_node
    test3 = create_mock_node
    test1 = create_mock_node [test2, test3]
    root_node = mock :title => nil, :node_type => 'R', :live_revisions => [0], :node_path => nil, :id => 1, :children => [test1]

    options = {:root_page => root_node.id, :levels => 5, :excluded => [test2.id], :included => []}

    @rnd = generate_page_renderer('automenu', options)
    @rnd.paragraph.should_receive(:language).any_number_of_times.and_return('en')

    SiteNode.should_receive(:find_by_id).with(root_node.id).and_return(root_node)

    root_node.children.each do |test_node|
      test_node.should_receive(:menu).and_return([test_node])
      test_node.should_receive(:active_revision).and_return(page_revision)
      test_node.should_receive(:is_a?).with(SiteNode).and_return(test_node)
    end

    test1.children.each do |test_node|
      test_node.should_receive(:menu).and_return([test_node])
      test_node.should_receive(:active_revision).and_return(page_revision) unless test_node.id == test2.id
      test_node.should_receive(:is_a?).with(SiteNode).and_return(test_node) unless test_node.id == test2.id
    end

    @output = renderer_get @rnd
    @output.status.should == '200 OK'
  end

end
