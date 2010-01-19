require File.dirname(__FILE__) + "/../../spec_helper"

describe Editor::MenuController do

  reset_domain_tables :end_users, :site_versions, :page_revisions, :site_nodes, :page_paragraphs

  it "should be able to render menu paragraph" do
    mock_editor
    paragraph_controller_helper('/page', '/editor/menu/menu')
    @output = paragraph_controller_get 'menu'
    @output.status.should == '200 OK'
  end

  it "should be able to add a links to a menu" do
    mock_editor
    paragraph_controller_helper('/page', '/editor/menu/menu')
    link1 = {:title => 'Test', :dest => 'url', :url => '/test.html'}
    link2 = {:title => 'Test2', :dest => 'url', :url => '/test2.html'}
    link3 = {:title => 'Test3', :dest => 'url', :url => '/test3.html'}
    link4 = {:title => 'Test4', :dest => 'url', :url => '/test4.html'}
    args = {:item => {'0' => link1.merge(:level => 1), '1' => link2.merge(:level => 2), '2' => link3.merge(:level => 3), '3' => link4.merge(:level => 1)}}
    @paragraph.data.should == {}
    @output = paragraph_controller_post 'menu_save', args
    @paragraph.reload
    @paragraph.data.should == {:menu => [link1.merge(:menu => [link2.merge(:menu => [link3])]), link4]}
  end

  it "should be able to render automenu paragraph" do
    mock_editor
    paragraph_controller_helper('/page', '/editor/menu/automenu')
    @output = paragraph_controller_get 'automenu'
    @output.status.should == '200 OK'
  end

  it "should be able to render bread_crumbs paragraph" do
    mock_editor
    paragraph_controller_helper('/page', '/editor/menu/bread_crumbs')
    @output = paragraph_controller_get 'bread_crumbs'
    @output.status.should == '200 OK'
  end

  it "should be able to render site_map paragraph" do
    mock_editor
    paragraph_controller_helper('/page', '/editor/menu/site_map')
    @output = paragraph_controller_get 'site_map'
    @output.status.should == '200 OK'
  end

  it "should be able to build menu preview" do
    mock_editor
    paragraph_controller_helper('/page', '/editor/menu/automenu')
    page1 = @site_node.add_subpage('test')
    revision1 = PageRevision.create :revision_container => page1, :language => 'en', :active => true, :created_by => @myself, :updated_by => @myself
    page2 = @site_node.add_subpage('test2')
    revision2 = PageRevision.create :revision_container => page2, :language => 'en', :active => true, :created_by => @myself, :updated_by => @myself
    page1.id.should_not be_nil
    page2.id.should_not be_nil

    args = {:menu => {:root_page => @site_node.id, :lock_level => "no", :levels => "5", :include_path => "0"}}
    @output = paragraph_controller_get 'automenu_preview', args
    @preview = controller.build_preview(@site_node.id, 5, [])
    @preview[0][0][:node_id].should == page1.id
    @preview[0][1][:node_id].should == page2.id
    @preview[1][0].should == page1.id
    @preview[1][1].should == page2.id
  end

end
