require File.dirname(__FILE__) + "/../spec_helper"

describe WebivaFormElements, :type => :view do

  reset_domain_tables :site_nodes, :site_versions, :page_revisions, :page_paragraphs

  class TestModel < HashModel
    attributes :test => nil, :test2 => nil, :test_array => [], :test_array2 => []
  end

  before(:each) do
    @object = TestModel.new({ })
    assigns[:object] = @object
  end

  def single_field_helper(field,extra='')

    txt = <<-EOF
<% cms_form_for :form, @object do |f| %>
   <%= f.#{field} :test#{extra} %>
<% end -%>
EOF
    txt
  end
  
  describe "file upload fields" do 

    before(:each) do
      fdata = fixture_file_upload("files/rails.png",'image/png')
      @df = DomainFile.create(:filename => fdata)
      @object.test = @df.id
    end

    after(:each) do
      @df.destroy
    end

    it "should be able to render an upload image field " do
      render :inline => single_field_helper('upload_image')
      response.should have_tag("input[type=file]")
    end

    it "should be able to render an upload document field " do
      render :inline => single_field_helper('upload_document')
      response.should have_tag("input[type=file]")
    end

    it "should be able to render an image list" do
      @object.test_array = [ @df.id ]
      render :inline => single_field_helper('image_list',"_array")
      response.should have_tag('input#form_test_array')
    end
  end

  it "should be able to render a multi-content-selector" do
    @target = EndUser.push_target('svend@karlson.com')
    @object.test = @target.id
    render :inline => single_field_helper('multi_content_selector',",EndUser")
    response.should have_tag('div#form_test_values')
  end

  it "should be able to render a content-selector" do
    @target = EndUser.push_target('svend@karlson.com')
    @object.test = @target.id
    render :inline => single_field_helper('content_selector',",EndUser")
    response.should have_tag('input#form_test')
  end

  it "should be able to render an unsorted selector " do
    render :inline => single_field_helper('unsorted_selector',",[['One',1],['Two',2]],[1]")
    response.should have_tag("select")
  end

  it "should be able to render a price range" do
    @object.test_array = [ "0","1.57"]
    @object.test_array2 = [ "1.56","1.44"]

    render :inline => single_field_helper('price_range',"_array, :test_array2, :measure => 'USD',:units => 'USD'")
  end

  it "should be able to render price_classes" do
    @object.test_array = {  'a' => 45, 'b' => 67 }
    
    render :inline => single_field_helper('price_classes',"_array, [['Class One','a'],['Class Two','b']] ")
    response.should have_tag('input[value=45]')
    response.should have_tag('input[value=67]')
    
  end

  it "should be able to render the filemanager folder selector" do
    render :inline => single_field_helper('filemanager_folder')
    response.should have_tag('span#form_test_name')
    response.should have_tag('input#form_test')
  end

  it "should be able render a end_user_selector" do
    @target = EndUser.push_target('svend@karlson.com')
    @object.test = @target.id
    render :inline => single_field_helper('end_user_selector',",:no_name => true")
    response.should have_tag('div.autocomplete')
  end


  it "should be able to render an autocomplete" do
    @target = EndUser.push_target('svend@karlson.com')
    @object.test = @target.id
    render :inline => single_field_helper('autocomplete_field',",'/test'")
    response.should have_tag('div.autocomplete')
  end

  it "should be able to render the page selector" do
    @page = SiteVersion.default.root.add_subpage('tester')
    @page2 = SiteVersion.default.root.add_subpage('tester2')

    render :inline => single_field_helper('page_selector')
    response.should have_tag("option[value=#{@page.id}]")
    response.should have_tag("option[value=#{@page2.id}]")
   
  end
   
  it "should be able to render the url selector" do
    @page = SiteVersion.default.root.add_subpage('tester')
    @page2 = @page.add_subpage('tester2')

    render :inline => single_field_helper('url_selector')
    response.should have_tag("option[value=#{@page.node_path}]")
    response.should have_tag("option[value=#{@page2.node_path}]")
   
  end

  it "should be able to render a ordered array" do
    render :inline => single_field_helper('ordered_array',"_array,[['One',1],['Two',2]]")
    response.should have_tag("select")
  end

  it "should be able to render a access_control" do
    @object.should_receive(:test_array?).and_return(true)
    @object.should_receive(:test_array_authorized).at_least(:once).and_return([])

    @object.test_array = [ 1 ]
    render :inline => single_field_helper('access_control','_array')
    response.should have_tag("select")
    
  end
  

end
