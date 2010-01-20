require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../mail_template_spec_helper"

describe MailTemplate do
  
  include MailTemplateSpecHelper

  reset_domain_tables :mail_templates
  
  
  

  before(:each) do
    @templ = MailTemplate.create(:name => 'Test',:language => 'eng', :subject => 'Test Subject')
  end

  
  describe 'process text, images, and variables for template generation' do
    # much of the template model and controller are for processing text.

    it 'should return the format string from format function' do 
      MailTemplate.create(:name => "M Template Test 2", :language => 'eng', :template_type => 'site', :subject =>  'HTML style templ')
      
    end
    
    it 'should have list of attachments' do 
      MailTemplate.create(:name => "M Template Test 3", :language => 'eng', :template_type => 'site', :attachments => {1,'blah'}, :subject =>  'has attachments')

      
    end
    it 'should render text for template'
      
    
    it 'should render html for template'
    
    
    
    it 'should replace html vars with other vars'
    it 'should create correct image URLS'
    it 'should generate a link for online viewing'
    it 'should add subscribe / unsubscribe links'
    it 'should generate track links'
    it 'should make all site links external'
  end
  
  
  describe 'create template' do
    
    it 'should get a list of site templates' do
      MailTemplate.create(:name => "M Template Test 2", :language => 'eng', :template_type => 'site', :subject =>  'test1')
      MailTemplate.create(:name => "M Template Test 3", :language => 'eng', :template_type => 'site', :subject =>  'test2')
      MailTemplate.create(:name => "M Template Test 4", :language => 'eng', :template_type => 'campaign', :subject =>  'test3')
      MailTemplate.create(:name => "M Template Test 5", :language => 'eng', :template_type => 'campaign', :subject =>  'test4')
      
      @site_tmpl = MailTemplate.site_template_options
      
      @site_tmpl[0][1].should == 1
      @site_tmpl[1][1].should == 2

    end
    
    it 'should get a list of campaign templates' do
      MailTemplate.create(:name => "M Template Test 2", :language => 'eng', :template_type => 'site', :subject =>  'test1')
      MailTemplate.create(:name => "M Template Test 3", :language => 'eng', :template_type => 'site', :subject =>  'test2')
      MailTemplate.create(:name => "M Template Test 4", :language => 'eng', :template_type => 'campaign', :subject =>  'test3')
      MailTemplate.create(:name => "M Template Test 5", :language => 'eng', :template_type => 'campaign', :subject =>  'test4')
      
      @campaign_tmpl = MailTemplate.campaign_template_options
      #   raise @campaign_tmpl.inspect 
      
      @campaign_tmpl[1][1].should == 5
      @campaign_tmpl[0][1].should == 4
      
    end 
    
    it 'template should be valid' do
      @templ.id.should be_valid
    end
    
    it 'should fail to create record if create_type is design and template id is not passed' do
      @tpl = MailTemplate.create(:name => "M Template Test 1", :language => 'eng', :template_type => 'site', :create_type => 'design', :subject => 'Design without ID')
      
      @tpl.should_not be_valid
    end
    
    
    
  end
  
  describe 'send template' do
    
    it 'should deliver templ template to end user' do
      @tmpl = MailTemplate.find(:last)
      @tmpl.deliver_to_address('daffy@mywebiva.com')
    end

    
    it 'should deliver templ template to email address' do

      create_end_user

      @re_vars = {:first_name => "FirstName"} 
      @tmpl = MailTemplate.find(:last)
      @tmpl.deliver_to_name('bunny1', @re_vars)
    end


  end
  
  
end
