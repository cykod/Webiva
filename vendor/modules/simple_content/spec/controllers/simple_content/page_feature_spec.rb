require  File.expand_path(File.dirname(__FILE__)) + '/../../simple_content_spec_helper'

describe SimpleContent::PageFeature, :type => :view do

  reset_domain_tables :simple_content_models

  before(:each) do
    @feature = build_feature('/simple_content/page_feature')
    @simple_content_model = SimpleContentModel.create :name => 'Test', :content_model_fields => [{:name => 'Title', :required => true, :field_type => 'string'}]
    @options = SimpleContent::PageController::StructuredViewOptions.new :simple_content_model_id => @simple_content_model.id, :data => {:title => 'Test'}
  end

  it "should render structured view" do
    @output = @feature.simple_content_page_structured_view_feature(:options => @options)
  end
end
