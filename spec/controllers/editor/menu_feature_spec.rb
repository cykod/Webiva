require File.dirname(__FILE__) + "/../../spec_helper"

describe Editor::MenuFeature, :type => :view do

  reset_domain_tables :end_users, :site_versions, :page_revisions, :site_nodes, :site_node_modifiers, :page_paragraphs

  before(:each) do
    @feature = build_feature('/editor/menu_feature')
  end

  it "should display a menu" do
    link2 = {:title => 'Test2', :link => '/test2.html'}
    link1 = {:title => 'Test', :link => '/test.html', :menu => [link2]}
    menu = [link1]

    @output = @feature.menu_feature({:url =>  '/test.html', :menu => menu})
    @output.should include(link2[:link])
  end

  it "should display a menu" do
    link1 = {:title => 'Test', :link => '/test.html', :page => nil, :menu_title => 'Test'}
    link2 = {:title => 'Test2', :link => '/test2.html', :page => nil, :menu_title => 'Test2'}

    data = { :parent => [link1, link2],
             :current => { :title => link2[:title],
                          :menu_title => link2[:menu_title],
                          :link => link2[:link],
                          :page => nil }
           }

    @output = @feature.bread_crumb_feature(data)
    @output.should include(link2[:link])
  end

  it "should display a site map" do
    data = { :entries => [ { :title => 'Home Page', :level => 1, :link => "/" },
	                   { :title => 'Sub Page 1', :level => 2, :link => "/sub" },
                           { :title => 'Sub Page 2', :level => 2, :link => "/sub2" }
                         ]
           }
  
    @output = @feature.site_map_feature(data)
    @output.should include('Sub Page 2')
  end

end
