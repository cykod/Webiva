require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../mail_template_spec_helper"

describe MailTemplate do
  
  include MailTemplateSpecHelper
  include ActionController::Assertions::SelectorAssertions # for site template stuff

  reset_domain_tables :mail_templates,:domain_file
  
  before(:each) do
    ActionMailer::Base.delivery_method = :test  
    ActionMailer::Base.perform_deliveries = true  
    ActionMailer::Base.deliveries = []  
    
    
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
     it 'should determine the body format when html' do
      @tmpl = MailTemplate.find_by_subject('Test Default2')
      @tf = @tmpl.body_format
      @tf.should == 'html'
    end
    it 'should determine th body format when text' do
      @tmpl = MailTemplate.find_by_subject('Test Default')
      @tf = @tmpl.body_format
      @tf.should == 'text'
      @tf.should_not == 'html'
      @tf.should_not == 'none'
      @tf.should_not == 'both'
    end
    it 'should create correct links' do
      @image = DomainFile.find_by_name('rails.png')
      @image_path = Configuration.domain_link(@image.prefix)
      @body_html = "<p>This is the image: <img src='%s' \/>" % @image_path
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
      @prepared_html = @tmpl.replace_image_sources
      @prepared_html.should == @body_html    
    end
    it 'should prepare a template for mailing' do
      @image = DomainFile.find_by_name('rails.png')
      @image_path = Configuration.domain_link(@image.prefix)
      @body_html = "<p>This is the image: <img src=\"%s\" \/>" % @image_path
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
      @prepared_html = @tmpl.prepare_to_send
      @prepared_html.should ==  @body_html
    end

  end  


  describe "mail templates with design templates" do
    reset_domain_tables :site_templates,:site_template_rendered_parts,:site_template_zones

    it 'it should prepare the template and substitute correctly' do
      create_end_user
      create_mail_tmpl_text
      @template_html = <<-EOF
<h1 id='header'>Mail Header, Yay!</h1>
<table width='100%'>
<tr>
  <td class='yellow'>
    <cms:zone name='Template'/>
  </td>
</tr>
</table>
EOF
      @style_design = <<-EOF
.yellow { 
  color:yellow; 
  font-weight:bold;
}


#header { 
  font-size:19px;
}

EOF

      @tpl = SiteTemplate.create(:template_type => 'mail',:name => 'Mail Template',:template_html => @template_html,:style_design => @style_design)
      create_complete_template( :site_template_id => @tpl.id )
      @tmpl = MailTemplate.find(:last)

      @prepared_html = @tmpl.prepare_to_send
      @prepared_html.should have_tag('h1',:style=>'font-size:19px;')
      @prepared_html.should have_tag('td',:style=>'color:yellow;font-weight:bold;')
      @tmpl.deliver_to_address('daffy@mywebiva.com')
      ActionMailer::Base.deliveries.size.should == 1  
    end
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
    it 'should create a copy of itself' do
      create_mail_tmpl_text({:create_type => '', :subject => 'make a copy'})
      @tmpl = MailTemplate.find(:last)
      @tmpl.duplicate
      @tmpl2 = MailTemplate.find(:last)
      @tmpl2.name.should == 'default test insert (Copy)'
    end
  end  
  describe 'send template' do
    it 'should deliver templ template to end user' do      
      create_end_user
      create_mail_tmpl_text
      @tmpl = MailTemplate.find(:last)
      @tmpl.deliver_to_address('daffy@mywebiva.com')
      ActionMailer::Base.deliveries.size.should == 1  
        
    end   
    it 'should deliver templ template to email address' do
      create_end_user
      create_mail_tmpl_text
      @re_vars = {:first_name => "FirstName"} 
      @tmpl = MailTemplate.find(:last)
      @user = EndUser.find_by_username('bunny1')
      @tmpl.deliver_to_user(@user, @re_vars)
      ActionMailer::Base.deliveries.size.should == 1  

    end
  end  
end
