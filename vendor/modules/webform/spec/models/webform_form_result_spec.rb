require  File.expand_path(File.dirname(__FILE__)) + '/../webform_spec_helper'

describe WebformFormResult do

  reset_domain_tables :webform_forms, :webform_form_results, :end_users

  it "should require a webform_form" do
    @result = WebformFormResult.new
    @result.valid?
    @result.should have(1).errors_on(:webform_form_id)
  end

  describe "valid webform with content/core_feature/email_target_connect feature" do
    before(:each) do
      fields = [
        {:name => 'First Name', :field_type => 'string', :field_module => 'content/core_field'},
        {:name => 'Last Name', :field_type => 'string', :field_module => 'content/core_field'},
        {:name => 'Email', :field_type => 'email', :field_module => 'content/core_field'}
      ]

      features = [{:feature_handler => 'content/core_feature/email_target_connect', :feature_options => {:matched_fields => {:email => 'end_user.email', :first_name => 'end_user.first_name', :last_name => 'end_user.last_name'}}}]

      @webform_form = WebformForm.new :name => 'Test'
      @webform_form.content_model_features = features
      @webform_form.content_model_fields = fields
      @webform_form.save
    end

    it "should be able to save webform data and create an end user" do
      data = {:first_name => 'Tester', :last_name => 'Laster', :email => 'webform-tester@test.dev'}

      @result = WebformFormResult.new :webform_form_id => @webform_form.id
      @result.assign_entry data

      assert_difference 'EndUser.count', 1 do
        @result.save.should be_true
      end

      @end_user = EndUser.find_by_email('webform-tester@test.dev')
      @end_user.should_not be_nil
      @end_user.first_name.should == 'Tester'
      @end_user.last_name.should == 'Laster'
      @end_user.name.should == 'Tester Laster'
    end
  end
end
