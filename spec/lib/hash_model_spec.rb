require File.dirname(__FILE__) + "/../spec_helper"

describe HashModel do

  def create_hash_model_class(strict=false, attributes={})
    @cls = Class.new(HashModel)
    @cls.attributes attributes
    @cls.send(:define_method, :strict?) { strict }
    @cls
  end

  reset_domain_tables :site_nodes, :site_version, :domain_files

  it "should return nil for any undefined attribute or method" do
    @model = HashModel.new nil
    @model.url.should be_nil
  end

  it "should raise exception for any undefined attribute or method" do
    @model = create_hash_model_class(true, :url => nil).new :url => '/'
    @model.url.should == '/'
    lambda { @model.url_not_found }.should raise_error
  end

  it "should remember default values" do
    @cls = create_hash_model_class(false, :page_id => 50, :page_number => 80, :value => 'one')

    @model = @cls.new :page_id => '5', :page_number => '4', :value => '3'
    @model.valid?
    @model.page_id.should == 5
    @model.defaults[:page_id].should == 50
    @model.page_number.should == '4'
    @model.defaults[:page_number].should == 80
  end

  it "should be able to setup integer_options" do
    @cls = create_hash_model_class(false, :page_id => nil, :page_number => nil, :page_value => nil)
    @cls.integer_options :page_value

    @model = @cls.new :page_id => '5', :page_number => '4', :page_value => '3'
    @model.valid?
    @model.page_id.should == 5
    @model.page_number.should == '4'
    @model.page_value.should == 3
  end

  it "should be able to setup integer_options" do
    @cls = create_hash_model_class(false, :page_value => nil)

    @model = @cls.new :page_value => '3'
    @model.valid?
    @model.page_value.should == '3'
    @model.option_to_i(:page_value)
    @model.page_value.should == 3
  end

  it "should be able to setup integer_array_options" do
    @cls = create_hash_model_class(false, :page_values => [])
    @cls.integer_array_options :page_values

    @model = @cls.new :page_values => ['3','4','5']
    @model.valid?
    @model.page_values.should == [3,4,5]
  end

  it "should be able to setup float_options" do
    @cls = create_hash_model_class(false, :money => nil)
    @cls.float_options :money

    @model = @cls.new :money => '1.5'
    @model.valid?
    @model.money.should == 1.5
  end

  it "should be able to setup domain_file_options" do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    @df = DomainFile.create(:filename => fdata)

    @cls = create_hash_model_class(true, :file_id => nil)
    @cls.domain_file_options :file_id

    @model = @cls.new :file_id => @df.id.to_s
    @model.valid?
    @model.file_id.should == @df.id
    @model.file_file.should == @df
    @model.file_url.should == @df.url
    @model.file_full_url.should == @df.full_url
  end

  it "should be able to setup boolean_options" do
    @cls = create_hash_model_class(false, :selected => nil)
    @cls.boolean_options :selected

    @model = @cls.new :selected => 'true'
    @model.valid?
    @model.selected.should be_true

    @model = @cls.new :selected => '1'
    @model.valid?
    @model.selected.should be_true

    @model = @cls.new nil
    @model.valid?
    @model.selected.should be_false

    @model = @cls.new :selected => 'false'
    @model.valid?
    @model.selected.should be_false

    @model = @cls.new :selected => '0'
    @model.valid?
    @model.selected.should be_false
  end

  it "should be able to setup page_options" do
    node = SiteVersion.default.root_node.add_subpage('blog')
    @cls = create_hash_model_class(false, :page_id => nil)
    @cls.page_options :page_id

    @model = @cls.new :page_id => node.id.to_s
    @model.valid?
    @model.page_id.should == node.id
    @model.page_url.should == '/blog'
    @cls.current_page_opts.should == [:page_id]
  end

  it "should be able to validate data" do
    @cls = create_hash_model_class(false, :page_id => nil)
    @cls.validates_presence_of :page_id

    @model = @cls.new nil
    @model.valid?.should be_false
    @model.errors.should have(1).errors_on(:page_id)
  end

  it "should be able to return all attribute data passed to the hash and only create a hash from attributes" do
    @cls = create_hash_model_class(false, :page_id => nil, :test => nil, :me => 7)

    @model = @cls.new :page_id => '1', :value => 'one'
    @model.valid?
    @model.page_id.should == 1
    @model.to_h.should == {:page_id => 1, :me => 7, :test => nil}
    @model.to_passed_hash.should == {:page_id => 1}
  end

  it "should be able to return human names" do
    class FieldOptions < HashModel
      attributes :page_id => nil
    end

    @model = FieldOptions.new :page_id => '1'
    @model.valid?

    FieldOptions.human_name.should == 'Field Options'
    FieldOptions.human_attribute_name(:page_id).should == 'Page'
  end
  
  describe "Page Options" do

    reset_domain_tables :page_paragraphs, :page_revisions

    before(:each) do
      @about = SiteVersion.current.root.push_subpage 'about'
      @version2 = SiteVersion.current.copy "test"

      @cls = create_hash_model_class(false, :page_id => nil)
      @cls.page_options :page_id
    end
    
    it "should be able to change page options to a different site version" do
      @model = @cls.new :page_id => @about.id
      @model.page_id.should == @about.id
      @about2 = @version2.site_nodes.find_by_title 'about'
      @about2.should_not be_nil
      @model.fix_page_options @version2
      @model.page_id.should == @about2.id
    end
  end
end
