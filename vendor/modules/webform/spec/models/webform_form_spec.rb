require  File.expand_path(File.dirname(__FILE__)) + '/../webform_spec_helper'

describe WebformForm do

  reset_domain_tables :webform_forms

  it "should require a name" do
    @webform_form = WebformForm.new
    @webform_form.valid?
    @webform_form.should have(1).errors_on(:name)
  end

  it "should be able to add all field types" do
    @field_types = ContentModel.simple_content_field_options
    @model = WebformForm.new :name => 'Test'

    fields = []
    @field_types.each do |type|
      content_field = ContentModel.content_field('content/core_field', type[1].to_s)
      fields << {:name => type[0].to_s, :field_type => type[1].to_s, :field_module => 'content/core_field'}
    end

    features = [{:feature_handler => 'content/core_feature/email_target_connect', :feature_options => {:matched_fields => {:email => 'end_user.email'}}}]

    @model.content_model_features = features
    @model.content_model_fields = fields
    @model.save.should be_true

    @data_mode = @model.content_model.create_data_model(nil)
  end

  it "should not loose the relation_name when saving twice" do
    @model = WebformForm.new :name => 'Test'
    content_field = ContentModel.content_field('content/core_field', 'image')
    fields = [{:name => 'Image', :field_type => 'image', :field_module => 'content/core_field'}]

    @model.content_model_fields = fields
    @model.save.should be_true

    @data_mode = @model.content_model.create_data_model(nil)
    @data_mode.respond_to?(:image_id).should be_true

    image_field = @model.content_model_fields[0];
    image_field.field.should == 'image_id'
    image_field.relation_name.should == 'image'

    @model.content_model_fields = fields
    @model.save.should be_true

    image_field = @model.content_model_fields[0];
    image_field.field.should == 'image_id'
    image_field.id.should == :image_id
    image_field.relation_name.should == 'image'
  end
end
