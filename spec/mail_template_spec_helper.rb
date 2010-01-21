module MailTemplateSpecHelper
  def create_end_user(email='bugsbunny@mywebiva.com', options={:first_name => 'TestBugs', :last_name => 'TestBunny', :username => 'bunny1'})
    EndUser.push_target(email, options)
  end

  def create_mail_tmpl_text( options={})      
    MailTemplate.create({:body_type => 'text',:name => 'default test insert',:subject => 'Test Default',:language => 'en',:template_type => 'site',:body_text => "this is the test body"}.merge(options))
  end

    def create_mail_tmpl_html( options={})      
    MailTemplate.create({:body_type => 'html',:name => 'default test insert2',:subject => 'Test Default2',:language => 'en',:template_type => 'site',:body_text => "<em>this is the test body</em>"}.merge(options))
  end
  
   def create_mail_tmpl_with_re_vars(options={})
     MailTemplate.new({:name => 'Test Tmpl W/ Variables', :subject => 'test', :template_type => 'site'}.merge(options))
   end

end
