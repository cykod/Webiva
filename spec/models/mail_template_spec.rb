require File.dirname(__FILE__) + "/../spec_helper"


describe MailTemplate do
  
  reset_domain_tables :mail_templates
  
  
  before(:each) do
    @templ = MailTemplate.create(:name => 'Test',:language => 'eng', :subject => 'Test Subject')
  end

  
  it 'template should be valid' do
    @templ.id.should be_valid
  end
  
  it 'should fail to create record if create_type is design and template id is not passed' do
      @tpl = MailTemplate.create(:name => "M Template Test 1", :language => 'eng', :template_type => 'site', :create_type => 'design', :subject => 'Design without ID')
    
    @tpl.should_not be_valid
  end

  it 'should deliver template to X address'
  
  it 'should deliver template to X user'
  it 'should return the format string from format function' do 
    MailTemplate.create(:name => "M Template Test 2", :language => 'eng', :template_type => 'site', :subject =>  'HTML style templ')
    
  end
  
  it 'should have list of attachments'
  it 'should render text for template'
  it 'should render html for template'
  it 'should generate parepared email'
  it 'should replace html vars with other vars'
  it 'should create correct iamge URLS'
  it 'should generate a link for online viewing'
  it 'should add subscribe / unsubscribe links'
  it 'should generate track links'
  it 'should make all site links external'
  
end

