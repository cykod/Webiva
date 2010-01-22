require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../mail_template_spec_helper"

describe MailTemplateMailer do
  
  include MailTemplateSpecHelper

  reset_domain_tables :mail_templates,:domain_file
  
  before(:each) do
    create_end_user

    @templ = create_mail_tmpl_text
    @templ2 = create_mail_tmpl_html

    fdata = fixture_file_upload("files/rails.png",'image/png')
    @df = DomainFile.create(:filename => fdata) 

    ActionMailer::Base.delivery_method = :test  
    ActionMailer::Base.perform_deliveries = true  
    ActionMailer::Base.deliveries = []  
    
  end
  after(:each) do 
    @df.destroy
  end 
  describe 'Send Email directly to address' do
    it 'should send a message to an email address' do
      @direct_mail = MailTemplateMailer.deliver_message_to_address('bugsbunny@mywebiva.net','test subject', { 
                                                                     :text => 'test text body', 
                                                                     :html => "<b>test html body", 
                                                                     :from => 'admin@mywebiva.net'} )
      ActionMailer::Base.deliveries.size.should == 1  
      @direct_mail.body.should =~ /<b>test html body/  
    end
    it 'should send mail template to address if available' do
      create_complete_template
      @tmpl_mail = MailTemplateMailer.deliver_to_address('bugsbunny@mywebiva.net',3)
      ActionMailer::Base.deliveries.size.should == 1  
      @tmpl_mail.body.should == @body_html      
    end    
    
    it 'should have  email and name if sent to user' do      
      create_complete_template
      @tmpl_mail = MailTemplateMailer.deliver_to_user(2,3, {:email => 'your_email'})
      ActionMailer::Base.deliveries.size.should == 1  
      @tmpl_mail.body.should == @body_html 
    end
  end
  
end
