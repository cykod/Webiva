require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../mail_template_spec_helper"
require "email_spec"



Spec::Runner.configure do |config|
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)
end


describe MailManagerController, "" do
  
  reset_domain_tables :mail_templates
  
  integrate_views
  

  
  
  describe "Creation / Options - it" do
   before(:each) do
      mock_editor 
    end
    it 'should create a new template' do    
      post('add_template',
           :mail_template => { 
             :name => 'test campaign mail templates',
             :template_type => 'campaign',
             :language => 'en',
             :create_type => 'blank',
             :category => 'test campaign category',
             :site_template_id => '',
             :master_template_id =>""},
           :path => "")
      @tmpl2 = MailTemplate.find(:last)
      @tmpl2.id.should_not be_nil
    end
  end
  describe 'control the template features and existence' do
    before(:each) do
      mock_editor
      
      fdata = fixture_file_upload("files/rails.png",'image/png')
      @df = DomainFile.create(:filename => fdata) 

      include MailTemplateSpecHelper

    end
    
    it 'should change a templates options' do
      @tmpl = MailTemplate.find_by_id(2)
      post('edit_template',
           :mail_template => { 
             :name => 'test campaign mail templates',
             :template_type => 'campaign',
             :language => 'en',
             :create_type => 'blank',
             :category => 'test campaign category',
             :site_template_id => '',
             :master_template_id =>"",
             :body_type => ["html","","text"],
             :body_text => "this is a long shot \n \n \n" },
           :email => ['enter email'],
           :path => @tmpl.id)
      @tmpl2 = MailTemplate.find(:last)
      @tmpl2.id.should_not be_nil
    end
    
    it 'should send a test of a template'
    it 'should generate the text of a template'
    it 'should delete a template'
    it 'should save a template'
    it 'should update a template'
    
    
    
  end
end


