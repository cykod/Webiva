require  File.expand_path(File.dirname(__FILE__)) + '/../../webform_spec_helper'

describe Webform::ManageController do

  reset_domain_tables :webform_forms, :webform_form_results

  it "should handle table list" do 
    mock_editor

    # Test all the permutations of an active table
    controller.should handle_active_table(:webform_table) do |args|
      post 'webform_table', args
    end
  end

  it "should be able to create webform" do
    mock_editor

    assert_difference 'WebformForm.count', 1 do
      post 'create', :content_model => { :name => 'Test Webform' }
      @model = WebformForm.find(:last)
      response.should redirect_to(:action => 'edit', :path => [@model.id])
    end
  end

  it "should redirect to create if there are no webforms" do
    mock_editor
    get 'index'
    response.should redirect_to(:action => 'create')
  end

  it "should be able to edit webform" do
    mock_editor

    @field_types = ContentModel.simple_content_field_options
    @model = WebformForm.create :name => 'Test'

    fields = {}
    @field_types.each_with_index do |type, idx|
      content_field = ContentModel.content_field('content/core_field', type[1].to_s)
      fields[idx] = {:name => type[0].to_s, :field_type => type[1].to_s, :field_module => 'content/core_field', :position => idx}
    end

    post 'edit', :path => [@model.id], :content_model => {:content_model_fields => fields}

    @model = WebformForm.find(@model.id)
    @model.content_model_fields.length.should == fields.length
  end

  it "should render the new field partial" do
    mock_editor
    post 'new_field', :add_field => {:name => 'Name', :field_type => 'content/core_field::string'}
    response.should render_template('_edit_field')
  end

  it "should be able to configure a webform with a feature and change name" do
    mock_editor
    fields = [
      {:name => 'First Name', :field_type => 'string', :field_module => 'content/core_field'},
      {:name => 'Last Name', :field_type => 'string', :field_module => 'content/core_field'},
      {:name => 'Email', :field_type => 'email', :field_module => 'content/core_field'}
    ]

    features = [{:feature_handler => 'content/core_feature/email_target_connect', :feature_options => {:matched_fields => {:email => 'end_user.email', :first_name => 'end_user.first_name', :last_name => 'end_user.last_name'}}}]

    @model = WebformForm.new :name => 'Test'
    @model.content_model_fields = fields
    @model.save

    post 'configure', :path => [@model.id], :content_model => {:name => 'New Test Name'}, :feature => features

    @model = WebformForm.find(@model.id)
    @model.name.should == 'New Test Name'
    @model.content_model_features.length.should == 1
  end

  it "should render the add feature partial" do
    mock_editor

    @model = WebformForm.new :name => 'Test'
    @model.save

    post 'add_feature', :path => [@model.id], :feature_handler => 'content/core_feature/email_target_connect'
    response.should render_template('_content_model_feature')
  end

  describe "valid webform form and results" do
    before(:each) do
      fields = [
        {:name => 'First Name', :field_type => 'string', :field_module => 'content/core_field'},
        {:name => 'Last Name', :field_type => 'string', :field_module => 'content/core_field'},
        {:name => 'Email', :field_type => 'email', :field_module => 'content/core_field'}
      ]

      features = [{:feature_handler => 'content/core_feature/email_target_connect', :feature_options => {:matched_fields => {:email => 'end_user.email', :first_name => 'end_user.first_name', :last_name => 'end_user.last_name'}}}]

      @model = WebformForm.new :name => 'Test'
      @model.content_model_fields = fields
      @model.content_model_features = features
      @model.save

      data = {:first_name => 'Tester', :last_name => 'Laster', :email => 'webform-tester@test.dev'}
      @result = WebformFormResult.new :webform_form_id => @model.id
      @result.assign_entry data
      @result.save
    end

    it "should handle results table list" do 
      mock_editor

      @model.id.should_not be_nil

      # Test all the permutations of an active table
      controller.should handle_active_table(:webform_result_table) do |args|
        args ||= {}
        post 'webform_result_table', args.merge(:path => [@model.id])
      end
    end

    it "should render the results page" do
      mock_editor
      get 'results', :path => [@model.id]
    end

    it "should render the result page" do
      mock_editor
      get 'result', :path => [@model.id, @result.id]
      @result.reload
    end

    it "should be able to mark a result as read" do
      mock_editor
      post 'webform_result_table', :path => [@model.id], :table_action => 'mark', :result => {@result.id.to_s => @result.id}
      @result.reload
      @result.reviewed?.should be_true
    end

    it "should be able to unmark a result as read" do
      mock_editor
      @result.update_attributes(:reviewed => true)
      post 'webform_result_table', :path => [@model.id], :table_action => 'unmark', :result => {@result.id.to_s => @result.id}
      @result.reload
      @result.reviewed?.should be_false
    end

    it "should be able to delete a result as read" do
      mock_editor

      post 'webform_result_table', :path => [@model.id], :table_action => 'delete', :result => {@result.id.to_s => @result.id}
      @result = WebformFormResult.find_by_id(@result.id)
      @result.should be_nil
    end

    it "should be able to delete a webform and all of its results" do
      mock_editor

      post 'webform_table', :table_action => 'delete', :webform => {@model.id.to_s => @model.id}
      @model = WebformForm.find_by_id(@model.id)
      @model.should be_nil
      @result = WebformFormResult.find_by_id(@result.id)
      @result.should be_nil
    end
  end
end
