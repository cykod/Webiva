require File.dirname(__FILE__) + "/../spec_helper"
require "email_spec"

  Spec::Runner.configure do |config|
    config.include(EmailSpec::Helpers)
    config.include(EmailSpec::Matchers)
  end


describe MailManagerController, "create a mail manager" do
  
  reset_domain_tables :mail_templates
  
  # include MailSpecHelper
  
  integrate_views
  
  before(:all) do
    
    #    create_2_mail_template_models_with_all_fields
  end
  
  describe "Mailtemplate" do 
    
    it 'should create a new template' do
      post('add_template', :icon => 'add.gif',  skip_before_filter :validate_is_editor, :template_type => 'campaign', 
           :name => 'test campaign mail templates')
      

      @template = MailTemplate.find(:last)
      @template.should_not be_nil

    end
    
    
    it 'should change a templates options'
    
    it 'should send a test of a template'
    it 'should generate the text of a template'
    it 'should delete a template'
    it 'should save a template'
    it 'should update a template'
    
    
    
  end
end
