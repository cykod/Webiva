require File.dirname(__FILE__) + "/../spec_helper"


describe HashModel do

  reset_domain_tables :site_versions, :site_nodes, :domain_files

  class TestHashModel < HashModel
    attributes :page_id => nil, :image_id => nil, :count => nil

    page_options :page_id
    domain_file_options :image_id
    integer_options :count
  end
  
  it "should be able to return a url" do
    pg = SiteVersion.default.root_node.add_subpage('testerama')

    mdl = TestHashModel.new(:page_id => pg.id)

    mdl.page_url.should == '/testerama'
  end

  it "should return a file url" do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    @df = DomainFile.create(:filename => fdata)
    
    mdl = TestHashModel.new(:image_id => @df.id)

    mdl.image_url.should == @df.url

    @df.destroy
  end

  it "should turn integer_options into ints"  do
    mdl = TestHashModel.new(:count => "10")
    mdl.valid?
    mdl.count.should == 10
  end

end
