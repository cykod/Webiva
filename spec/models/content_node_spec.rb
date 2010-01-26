require File.dirname(__FILE__) + "/../spec_helper"


describe ContentNode do

  @@paragraph_body = <<-EOF
<h1>Title the page</h1>
<p>
Some additional stuff<br/>
<b>Bolded!</b>
EOF


  reset_domain_tables :content_types,:content_nodes,:content_node_values, :site_nodes, :page_paragraphs, :page_revisions, :site_versions, :content_meta_types, :configurations

  it "should create the default content types" do
    ContentType.count.should == 0
    Editor::AdminController.content_node_type_generate
    ContentType.count.should == 1
  end

  it "should be able to create node values" do
    # Create a page
    
    Editor::AdminController.content_node_type_generate
    ContentType.count.should == 1

    @version = SiteVersion.create(:name => 'Default')
    @page = @version.root_node.add_subpage('my-page')

    updated_at = @page.content_node.updated_at

    rev = @page.active_revisions[0].create_temporary

    rev.page_paragraphs.create(:display_type=>'html',:display_body => @@paragraph_body )
    rev.make_real

    @page.reload

    @page.content_node.generate_content_values!

   # Make sure the content node value we're searching on contains the body
    @page.content_node.content_node_values[0].body.should include("Title the page")
    @page.content_node.content_node_values[0].body.should include("Some additional stuff")
    @page.content_node.content_node_values[0].body.should include("Bolded!")
  end

  it "should be able to index the site" do
    Editor::AdminController.content_node_type_generate
    @version = SiteVersion.create(:name => 'Default')

    # Home page / gets created automatically
    @home_page = @version.root_node.children[0]
    @page = @version.root_node.add_subpage('my-page')
    @page2 = @version.root_node.add_subpage('my-page2')
    @page3 = @version.root_node.add_subpage('my-page3')

    [@home_page, @page, @page2, @page3].each_with_index do |page,idx|
      page.active_revisions[0].page_paragraphs.create(:display_type=>'html',:display_body => @@paragraph_body + "<p>This is page #{idx}!</p>" )
    end
    
    Configuration.put('index_last_update',nil)
    
    ContentNodeValue.count.should == 0

    # Here we're actually updating the site index
    ContentType.update_site_index

    ContentNodeValue.count.should == 4

    
    # Now make sure each of the content node values contains the text
    # from each node
    ContentNodeValue.find(:all,:order => 'content_node_id').each_with_index do |nv,idx|
      nv.body.should include("This is page #{idx}!")
    end
    
  end

end
