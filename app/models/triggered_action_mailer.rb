# Copyright (C) 2009 Pascal Rettig.

class TriggeredActionMailer < ActionMailer::Base #:nodoc:all

  include ERB::Util
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  
  def self.send_email(data,options,user)
    users = EndUser.find(:all,:conditions => ["user_class_id = ?", options[:user_class]],:order => 'last_name,first_name')
    users.each do |usr| 
      self.deliver_email(usr.email,
                           options[:subject],
                           options[:custom_message],
                            nil,
                            data,
                           user
                           )
    end
  end
  
  def self.send_publication_email(data,options,user)
    body = options[:custom_message]
    
    if options[:publication_id]
      publication = ContentPublication.find_by_id(options[:publication_id])
    end
  
    users = EndUser.find(:all,:conditions => ["user_class_id = ?", options[:user_class]],:order => 'last_name,first_name')
    users.each do |usr| 
      self.deliver_email(usr.email,
                           options[:subject],
                           body,
                           publication,
                           data,
                           user
                           )
    end

  end
  
  def email(to_email,msg_subject,msg_body,publication=nil,data=nil,user=nil)

  
    subject     msg_subject
    recipients  to_email
    from        Configuration.reply_to_email
    sent_on     Time.now
    content_type 'text/html'
    @body        = {:msg_body => msg_body, :user => user, :data => data }
  
  end
  

end
