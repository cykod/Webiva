require File.dirname(__FILE__) + "/../spec_helper"


describe ContentNodeValue do

  @@paragraph_body = <<-EOF
<h1>Title the page</h1>
<p>
Some additional stuff<br/>
<b>Bolded!</b>
EOF


  reset_domain_tables :content_types,:content_nodes,:content_node_values, :site_nodes, :page_paragraphs, :page_revisions, :site_versions

  it "should be able to search node values" do
    Editor::AdminController.content_node_type_generate
    @version = SiteVersion.create(:name => 'Default')

    # Home page / gets created automatically
    @home_page = @version.root_node.children[0]
    @page = @version.root_node.add_subpage('my-page')
    @page2 = @version.root_node.add_subpage('my-page2')
    @page3 = @version.root_node.add_subpage('my-page3')

    [@home_page, @page, @page2, @page3].each_with_index do |page,idx|
      page.active_revisions[0].page_paragraphs.create(:display_type=>'html',:display_body => @@paragraph_body + "<p>This is page#{idx}!</p>" )
    end
    
    Configuration.put('index_last_update',nil)
    
    ContentNodeValue.count.should == 0

    # Here we're actually updating the site index
    ContentType.update_site_index

    ContentNodeValue.count.should == 4

    @results, @total_results = ContentNodeValue.search 'en', 'page2', :conditions => {:search_result => 1}, :limit => 10, :offset => 0
    @total_results.should == 1
    @results[0].title.downcase.should include('page2')
  end

end
