require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../mail_template_spec_helper"

describe MailTemplate do
  
  include MailTemplateSpecHelper

  reset_domain_tables :mail_templates,:domain_file
  
  before(:each) do
    @templ = create_mail_tmpl_text
    @templ2 = create_mail_tmpl_html

    fdata = fixture_file_upload("files/rails.png",'image/png')
    @df = DomainFile.create(:filename => fdata) 
  end
  after(:each) do 
#    @df.destroy # Make sure we get rid of the files in the system
  end
  
  
  describe 'process text, images, and variables for template generation' do
    it 'should return the format string from format function' do 
      MailTemplate.create(:name => "M Template Test 2", :language => 'eng', :template_type => 'site', :subject =>  'HTML style templ')
    end
    
    it 'should have list of attachments' do 
      @hasatt = create_mail_tmpl_html({:attachments => 1})  
    end
    it 'should render html for template' do
      @findtext = MailTemplate.text_generator("<a href='cool'>Cool</a>")
      @findtext.should == 'Cool'
    end
    it 'should locate template by name & language' do
      @name = 'default test insert'
      @tmpl = MailTemplate.fetch(@name)
      @tmpl.id.should == 1
    end 
    it 'should replace find  variables in body html' do
      create_end_user
      create_mail_tmpl_html({:subject => "%%username%% has signed up",
                              :body_html => "Dear, %%FirstName%% <p> Please verify that %%email%% is still your email address <br />",
                              :body_text => "Dear, %%happyman%%, we like you",
                              :body_type => "both"})
      @tmpl = MailTemplate.find(:last)
      @vars = @tmpl.get_variables
      @vars[0].should == 'FirstName'
      @vars[1].should == 'email'
    end
    it 'should determine if template is text type' do
      @tmpl = MailTemplate.find_by_subject('Test Default')
      @tf = @tmpl.is_text
      @tf.should == true
    end
    it 'should determine if template is html type' do
      @tmpl = MailTemplate.find_by_subject('Test Default2')
      @tf = @tmpl.is_html
      @tf.should == true
    end
    it 'should create correct links' do
      @image = DomainFile.find_by_name('rails.png')
      @image_path = "<img src=\"../../../system/storage/2/%s/%s\" height=\"200\" width=\"256\"" %  [@image.prefix, @image.name]      
      @body_html = "<p>This is the image:  %s" % @image_path
    

      @tmpl = MailTemplate.create({:name=>"Test Template Image",
        :template_type=>"site",
        :category=>"test cat",
        :site_template_id=>"",
        :body_type=> "html",
        :body_html=> @body_html,
        :language=>"en",
        :subject=>"this is the subject",
        :published_at=>"",
        :attachments=>"",
        :generate_text_body=>"0",
        :body_text=>"This is my test template \n \n  \n \nit is called template A \n "})
     
      @fix = @tmpl.replace_image_sources
      
      ### this is completely a mystery.. FIGURE THIS OUT

      
    end
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
      @site_tmpl[2][1].should == 3
      @site_tmpl[3][1].should == 4
    end
    it 'should get a list of campaign templates' do
      create_mail_tmpl_text({:name => '1', :template_type => 'site'})
      create_mail_tmpl_text({:name => '2', :template_type => 'site'})
      create_mail_tmpl_text({:name => '3', :template_type => 'campaign'})
      create_mail_tmpl_text({:name => '4', :template_type => 'campaign'})
      @campaign_tmpl = MailTemplate.campaign_template_options
      @campaign_tmpl[0][1].should == 5
      @campaign_tmpl[1][1].should == 6
    end    
    it 'template should be valid' do
      create_mail_tmpl_text
      @tmpl = MailTemplate.find(:last)
    end   
    it 'should fail to create record if create_type is design and template id is not passed' do
      create_mail_tmpl_text({:create_type => 'design', :subject => 'Design without ID'})
      @tmpl = MailTemplate.find_by_subject('Design without ID')
      @tmpl.should be_nil
    end          
  end  
  describe 'send template' do
    it 'should deliver templ template to end user' do      
      create_end_user
      create_mail_tmpl_text
      @tmpl = MailTemplate.find(:last)
    #  @tmpl.deliver_to_address('daffy@mywebiva.com')
    end   
    it 'should deliver templ template to email address' do
      create_end_user
      create_mail_tmpl_text
      @re_vars = {:first_name => "FirstName"} 
      @tmpl = MailTemplate.find(:last)
      @user = EndUser.find_by_username('bunny1')
    #  @tmpl.deliver_to_user(@user, @re_vars)
    end
  end  
end
