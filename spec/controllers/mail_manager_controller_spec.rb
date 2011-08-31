require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../mail_template_spec_helper"





describe MailManagerController, "" do
  reset_domain_tables :mail_templates, :domain_files, :end_users, :site_templates
  integrate_views
  include MailTemplateSpecHelper

  describe "Creation / Options - it" do
   before(:each) do
      mock_editor 
    end
    it 'should create a new template' do    
      post('add_template',
           :mail_template => { 
             :name => 'test campaign mail templates',
             :template_type => 'campaign',
             :body_text => 'body',
             :body_type => 'text',
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
      
      # add files for use as attachments and inclusions
      fdata = fixture_file_upload("files/rails.png",'image/png')
      @df = DomainFile.create(:filename => fdata) 
      
      # add a design template for emails
      SiteTemplate.create(:name => 'Default Template'.t,:template_html => "<cms:zone name='Main'/>",:template_type => 'site')
      SiteTemplate.create(:name => 'Test Mail Design Template'.t,:template_html => "<cms:zone name='Main'/>",:template_type => 'mail')

      # create a row with an inserted image tag which matches a file in the domain_files table
      @image = DomainFile.find_by_name('rails.png')
      @image_path = "%%your_email%% <img src=\"../../../system/storage/2/%s/%s\" height=\"200\" width=\"256\"" %  [@image.prefix, @image.name]      
      @body_html = "<p>This is the image:  %s" % @image_path      
      MailTemplate.create({:name=>"Test Template Image",:template_type=>"site",
                            :category=>"test cat", :site_template_id=>"",
                            :body_type=> "html", :body_html=> @body_html,
                            :language=>"en", :subject=>"this is the subject",
                            :published_at=>"", :attachments=>"",
                            :generate_text_body=>"0",
                            :body_text=>"This is a test mail template"})

      # generic post options
      @tmpl_post_options =  { :name => 'test campaign mail templates',:template_type => 'campaign',:language => 'en',:create_type => 'blank', :category => 'test campaign category',:generate_text_body => 1,:site_template_id => '',:master_template_id =>"",:body_type => ["html","","text"],:body_text => "this is a long shot \n \n \n" }
      
      # post options with a design template included
      @design_tmpl = SiteTemplate.find(:last,:conditions => {:template_type => 'mail'})
      @tmpl_post_options_with_design =  { :name => 'test campaign mail templates',:template_type => 'campaign',:language => 'en',:create_type => 'blank', :category => 'test campaign category',:generate_text_body => 1,:subject => 'test subject',:site_template_id => @design_tmpl.id,:master_template_id =>"",:body_type => ["html","","text"],:body_text => "this is a long shot \n \n \n" }
      
      # post options txt only 
      @tmpl_post_options_text_only =  { :name => 'test campaign mail templates',:template_type => 'campaign',:language => 'en',:create_type => 'blank', :category => 'test campaign category',:generate_text_body => 0,:subject => 'test subject',:site_template_id => '',:master_template_id =>"",:body_type => ["text"],:body_text => "this is a long shot \n \n \n" }

    end
   
    it 'should call load the templates page and render the active table' do
      @tmpl = MailTemplate.find(:last)
      post('templates', :path => '')
      response.body.should include('mail_manager/templates')
    end
    
    it 'should change a templates options' do
      @tmpl = MailTemplate.find(:last)
      post('edit_template', :mail_template => @tmpl_post_options, :email => ['enter email'],  :path => @tmpl.id)
      @tmpl2 = MailTemplate.find(:last)
      @tmpl2.id.should_not be_nil
    end
    it 'should refresh template when a design template is applied'  do
      @tmpl = MailTemplate.find(:last)
      Locale.should_receive(:language_code).at_least(:once).and_return('en')
      post('refresh_template', :mail_template => @tmpl_post_options_with_design, :path => '')
      @updated_tmpl = MailTemplate.find(:last)
     
      response.body.should include('mail_template[body_html]')
    end

    it 'should send a test of a template' do
      post('send_test_template',
           :html => "<br> <br> lots o txt </br> ", 
           :mail_template => @tmpl_post_options_text_only, 
           :email => ['daffy1@mywebiva.net'],  
           :path => 1)     
    end

    it 'should generate the text of a template' do      
      @tmpl_body = post('generate_text_body', :html => "<br/> <br/> lots o txt <br/> ", 
                        :mail_template => @tmpl_post_options, :email => ['daffy1@mywebiva.net'],  :path => 1)
      response.body.should include("lots o txt")
    end

    it 'should delete a template' do       
      @tmpl = MailTemplate.find(:last)
      @tmpl.id.should_not be_nil      
      post('delete_template',:template_id => 1)
    end

    it 'should save a template' do 
      post('edit_template', :mail_template => @tmpl_post_options, :email => ['daffy2@mywebiva.net'],  :path => 1)
      response.should redirect_to("http://test.host/website/mail_manager/templates?show_campaign=1")
      @tmpl = MailTemplate.find(:last)
      @tmpl.category.should == 'test campaign category'

    end
    it 'should update a template'do
      post('update_template',:template_id => 1, :mail_template => { :name => 'new name' })
      @tmpl = MailTemplate.find_by_id(1)
      @tmpl.should_not be_nil
      @tmpl.name.should == 'new name'
    end
    
    it 'should generate an active table' do      
      @tmpl = MailTemplate.find_by_id(1)   
      controller.should handle_active_table(:mail_templates_table) do |args|
        args[:path] = [@tmpl.id]
        post 'display_mail_templates_table', args
      end    
    end
  
  end
end


