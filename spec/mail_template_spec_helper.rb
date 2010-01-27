module MailTemplateSpecHelper
  def create_end_user(email='bugsbunny@mywebiva.com', options={:first_name => 'TestBugs', :last_name => 'TestBunny', :username => 'bunny1'})
    EndUser.push_target(email, options)
  end

  def create_mail_tmpl_text( options={})      
    MailTemplate.create({:body_type => 'text',:name => 'default test insert',:subject => 'Test Default',:language => 'en',:template_type => 'site',:body_text => "this is the test body"}.merge(options))
  end
  
  def create_mail_tmpl_html( options={})      
    MailTemplate.create({:body_type => 'html',:name => 'default test insert2',:subject => 'Test Default2',:language => 'en',:template_type => 'site',:body_html => "<em>this is the test body</em>"}.merge(options))
  end
  
  def create_mail_tmpl_with_re_vars(options={})
    MailTemplate.new({:name => 'Test Tmpl W/ Variables', :subject => 'test', :template_type => 'site'}.merge(options))
  end
  def create_mail_tmpl_html_with_images( options={})      
    MailTemplate.create({:body_type => 'html',:name => 'default test with images',:subject => 'Test Image',:language => 'en',:template_type => 'site'}.merge(options))
  end
  def create_complete_template( options={} )
   
    @image = DomainFile.find_by_name('rails.png')
    @image_path = "%%your_email%% <img src=\"../../../system/storage/2/%s/%s\" height=\"200\" width=\"256\"" %  [@image.prefix, @image.name]      
    @body_html = "<p>This is the image:  %s" % @image_path

    MailTemplate.create({:name=>"Test Template Image",:template_type=>"site",
                          :category=>"test cat", :site_template_id=>"",
                          :body_type=> "html", :body_html=> @body_html,
                          :language=>"en", :subject=>"this is the subject",
                          :published_at=>"", :attachments=>"",
                          :generate_text_body=>"0",
                          :body_text=>"This is a test template"}.merge(options))
    
  end
end
