require File.dirname(__FILE__) + "/../spec_helper"

# Test added version support by DomainFileVersion
# This tests a bunch of functionality on DomainFile as well

describe PageParagraph do

  reset_domain_tables :page_paragraphs, :domain_files, :domain_file_instances
  
  before(:each) do
    @para = PageParagraph.new(:display_type => 'html')
    
    fdata = fixture_file_upload("files/rails.png",'image/png')
    @df = DomainFile.create(:filename => fdata)
  end
  
  after(:each) do 
    @df.destroy
  end
  
  it "should render display_body_html to correct files on save and create domain file instances" do
    @para.display_body = "<div class='test'><img src='#{@df.editor_url}'/></div>"
    @para.save

    @para.regenerate_file_instances # Need to call manually 
    
    # Check the display body html was rendered
    @para.display_body_html.should == "<div class='test'><img src='#{@df.url}'/></div>" 

    @df.reload
    @df.instances.length.should == 1
    @inst = @df.instances[0]
    
    @inst.target.should == @para
    @inst.column.should == 'display_body'
    @inst.domain_file.should == @df
    
    @para.destroy
    @df.reload
    @df.instances.length.should == 0
    
  end
  
end
