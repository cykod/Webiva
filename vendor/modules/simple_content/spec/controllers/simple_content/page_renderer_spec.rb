require  File.expand_path(File.dirname(__FILE__)) + '/../../simple_content_spec_helper'

describe SimpleContent::PageRenderer, :type => :controller do
  controller_name :page
  integrate_views

  reset_domain_tables :simple_content_models

  def generate_page_renderer(paragraph, options={}, inputs={})
    @rnd = build_renderer('/page', '/simple_content/page/' + paragraph, options, inputs)
  end

  it "should render page structured_view" do
    @rnd = generate_page_renderer('structured_view')
    @rnd.should_receive(:render_paragraph).with(:nothing => true)
    renderer_get @rnd
  end

  it "should render page structured_view" do
    mock_editor
    @rnd = generate_page_renderer('structured_view')
    @rnd.should_receive(:render_paragraph).with(:text => 'Reconfigure paragraph')
    renderer_get @rnd
  end

  describe "with valid simple content model and data" do
    before(:each) do
      fdata = fixture_file_upload("files/rails.png",'image/png')
      @df = DomainFile.create(:filename => fdata)

      @simple_content_model = SimpleContentModel.create :name => 'Test', :content_model_fields => [{:name => 'Title', :required => true, :field_type => 'string'}, {:name => 'Image', :required => true, :field_type => 'image'}]
      @options = SimpleContent::PageController::StructuredViewOptions.new :simple_content_model_id => @simple_content_model.id, :data => {:title => 'String Title Test', :image_id => @df.id}
    end

    it "should render the data model" do
      @rnd = generate_page_renderer('structured_view', @options.to_h)
      @rnd.paragraph.site_feature = SiteFeature.new(
                  :feature_type => :any,
                  :body_html => <<-EOF)
<h1>Test Site Feature</h1>
<cms:feature>
<cms:image/> <b><cms:title/></b>
</cms:feature>
EOF

      renderer_get @rnd

      response.should have_tag('h1', :text => 'Test Site Feature')
      response.should have_tag('b', :text => 'String Title Test')
      response.should have_tag("img[src=#{@df.url}]")
    end

    
  end
end
