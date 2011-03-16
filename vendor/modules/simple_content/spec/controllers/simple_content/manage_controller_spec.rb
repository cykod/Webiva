require  File.expand_path(File.dirname(__FILE__)) + '/../../simple_content_spec_helper'

describe SimpleContent::ManageController do

  reset_domain_tables :simple_content_models

  it "should handle table list" do 
    mock_editor

    # Test all the permutations of an active table
    controller.should handle_active_table(:simple_content_table) do |args|
      post 'simple_content_table', args
    end
  end

  it "should be able to create simple content" do
    mock_editor

    assert_difference 'SimpleContentModel.count', 1 do
      post 'create', :content_model => { :name => 'Test Simple Content' }
      @model = SimpleContentModel.find(:last)
      response.should redirect_to(:action => 'edit', :path => [@model.id])
    end
  end

  it "should redirect to create if there are no simple content models" do
    mock_editor
    get 'index'
    response.should redirect_to(:action => 'create')
  end

  it "should be able to edit simple content" do
    mock_editor

    @field_types = ContentModel.simple_content_field_options
    @model = SimpleContentModel.create :name => 'Test'

    fields = []
    @field_types.each_with_index do |type, idx|
      content_field = ContentModel.content_field('content/core_field', type[1].to_s)
      fields[idx] = {:name => type[0].to_s, :field_type => type[1].to_s, :field_module => 'content/core_field', :position => idx}
    end

    post 'edit', :path => [@model.id], :content_model => {:content_model_fields => fields}

    @model = SimpleContentModel.find(@model.id)
    @model.content_model_fields.length.should == fields.length
  end

  it "should render the new field partial" do
    mock_editor
    post 'new_field', :add_field => {:name => 'Name', :field_type => 'content/core_field::string'}
    response.should render_template('_edit_field')
  end
end
