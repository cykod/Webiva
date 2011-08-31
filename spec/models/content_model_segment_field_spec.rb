require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../content_spec_helper"

describe ContentModelSegmentField do
  include ContentSpecHelper

  reset_domain_tables :content_model, :content_model_field

  ContentSpecHelper.setup_content_model_test_with_all_fields self
  
  it "should be able to create a segment field class for a custom content model" do
    model = @cm
    model.id.should_not be_nil
    cmf = ContentModelField.new(:name => "User",:field_type => 'belongs_to', :field_module => 'content/core_field',
                                :field_options => {:belongs_to => 'end_user'}  ).attributes
    model.update_table([cmf])
    model.reload

    field = model.content_model_fields.to_a.find { |f| f.field_type == 'belongs_to' && f.relation_class == EndUser }
    field.should_not be_nil
    cls = ContentModelSegmentField.create_custom_field_handler_class field
    cls.should_not be_nil

    cls.user_segment_fields[:cms_controller_spec_tests_string_field].should_not be_nil
    cls.user_segment_fields[:cms_controller_spec_tests_string_field][:type].should == UserSegment::CoreType::StringType
    cls.user_segment_fields[:cms_controller_spec_tests_string_field][:field].should == 'string_field'
    cls.user_segment_fields[:cms_controller_spec_tests_string_field][:name].should == 'string Field'
    cls.user_segment_fields[:cms_controller_spec_tests_string_field][:handler].should == cls
    cls.user_segment_fields[:cms_controller_spec_tests_email_field].should_not be_nil
    cls.user_segment_fields[:cms_controller_spec_tests_options_field].should_not be_nil
    cls.user_segment_fields[:cms_controller_spec_tests_us_state_field].should_not be_nil
    cls.user_segment_fields[:cms_controller_spec_tests_boolean_field].should_not be_nil
    cls.user_segment_fields[:cms_controller_spec_tests_integer_field].should_not be_nil
    cls.user_segment_fields[:cms_controller_spec_tests_currency_field].should_not be_nil
    cls.user_segment_fields[:cms_controller_spec_tests_date_field].should_not be_nil
    cls.user_segment_fields[:cms_controller_spec_tests_datetime_field].should_not be_nil
  end
end
