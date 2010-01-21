require File.dirname(__FILE__) + "/../spec_helper"

# Test added version support by DomainFileVersion
# This tests a bunch of functionality on DomainFile as well

describe PageParagraph do

  reset_domain_tables :page_paragraphs, :domain_files, :domain_file_instances, :site_nodes, :site_versions
  

  describe "File Instance Saving" do 
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

  describe "Canonical Paragraphs" do

    reset_domain_tables :content_types,:content_nodes, :content_meta_types


    class TestParagraphType < HashModel
      attributes :canonical_test_id => nil, :canonical_page_id => nil

      canonical_paragraph "CanonicalTest", :canonical_test_id
    end

    it "should be able to link canonical paragraphs types" do
      root = SiteVersion.default.root_node
      @pg = root.add_subpage('test_page')

      # Create a dummy content type
      @canonical_type = ContentType.create(:component => 'editor',
                         :container_type => 'CanonicalTest',
                         :container_id => 7,
                         :url_field => 'id',
                         :title_field => 'name',
                         :content_type => 'CanonicalTestNode')
      
      # Create a dummy paragraph
      para = @pg.live_revisions[0].page_paragraphs.create()
                                                        
      paragraph_options = TestParagraphType.new(:canonical_test_id => @canonical_type.container_id,
                                                :canonical_page_id => @pg.id )

      # make sure the paragraph sets the options
      para.should_receive(:paragraph_options).and_return(paragraph_options)
      para.link_canonical_type!
      
      @canonical_type.reload

      @canonical_type.detail_site_node_url.should == '/test_page'
    end

    class CanonicalTest
      def initialize(opts={ })
      end
      def self.find(*args)
        CanonicalTest.new
      end
      def url
        "fake_url"
      end
      def new_record?; false; end
    end

    class TestCanonicalParagraphType < HashModel
      attributes :canonical_test_id => nil, :canonical_page_id => nil

      meta_canonical_paragraph "CanonicalTest", :url_field => :url
    end

    it "should be able to link canonical meta paragraphs types" do
      root = SiteVersion.default.root_node
      @pg = root.add_subpage('test_page_2')

      # Create a dummy content type
      @canonical_type = ContentType.create(:component => 'editor',
                         :container_type => 'CanonicalTest',
                         :container_id => 7,
                         :url_field => 'id',
                         :title_field => 'name',
                         :content_type => 'CanonicalTestNode')
    
         # Create a dummy paragraph
      para = @pg.live_revisions[0].page_paragraphs.create()
                                                        
      paragraph_options = TestCanonicalParagraphType.new({ })

      para.should_receive(:paragraph_options).and_return(paragraph_options)
      para.link_canonical_type!
      
      @canonical_type.reload

      @canonical_type.detail_site_node_url.should == '/test_page_2/fake_url'
    end
  end
end
