require  File.expand_path(File.dirname(__FILE__)) + '/../../webform_spec_helper'

describe Webform::PageFeature, :type => :view do

  reset_domain_tables :webform_forms, :webform_form_results

  before(:each) do
    @feature = build_feature('/webform/page_feature')
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

    @result = WebformFormResult.new :webform_form_id => @model.id, :end_user_id => nil, :ip_address => '0.0.0.0', :name => 'Test Name'
    @options = Webform::PageController::FormOptions.new :webform_form_id => @model.id, :destination_page_id => nil, :email_to => nil, :captcha => nil

    @paragraph = mock :id => 1, :language => 'en'

    @captcha = WebivaCaptcha.new nil
  end

  it "should render webform form" do
    @feature.should_receive(:paragraph).any_number_of_times.and_return(@paragraph)
    @output = @feature.webform_page_form_feature(:options => @options, :result => @result)
    @output.should have_tag('input[type=text]', :name => 'results_1[first_name]')
    @output.should have_tag('input[type=text]', :name => 'results_1[last_name]')
    @output.should have_tag('input[type=text]', :name => 'results_1[email]')
    @output.should have_tag('input[type=submit]')
  end

  it "should render webform form when saved" do
    @feature.should_receive(:paragraph).any_number_of_times.and_return(@paragraph)
    @output = @feature.webform_page_form_feature(:options => @options, :result => @result, :saved => true)
    @output.should include('Thank you')
  end
end
