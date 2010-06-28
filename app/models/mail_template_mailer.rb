# Copyright (C) 2009 Pascal Rettig.

require 'mime/types'


# MailTemplateMailer is used to send MailTemplate's
# 
# See MailTemplate for a more detailed description, 
# MailTemplate#deliver_to_user and MailTemplate#deliver_to_address
# should be used in most cases. 
#
# If you don't have a MailTemplate however, you can use
# MailTemplateMailer#message_to_address to send a message directly without
# mail template 
class MailTemplateMailer < ActionMailer::Base
  include HandlerActions

  # Send a message inline to an email address
  #
  # Usage:
  #
  #     MailTemplateMailer.deliver_message_to_address(
  #                    'test@domain.com',
  #                    "This is the email subject",
  #                    :text => 'Text body',
  #                    :html => "<b>Html Body!</b>",
  #                    :from => 'Svend@karlson.com')
  #
  # Either :text or :html (or both) must be specified,
  # :from is optional and will use the default or the
  # Configuration reply to email
  def message_to_address(email,subj,options ={})
    subject subj
    recipients email
    
    if options[:from]
      from options[:from]
    elsif !Configuration.mailing_from.to_s.empty?
      from "\"#{Configuration.mailing_from}\" <#{Configuration.reply_to_email}>"
    else
      from Configuration.reply_to_email    
    end
    
    if options[:text] && options[:html]
      content_type "multipart/alternative"

      part :content_type => 'text/plain',
          :body => options[:text]
      part :content_type => "text/html", :transfer_encoding => '7bit',
          :body => options[:html]
    elsif options[:text]
      content_type 'text/plain'
      body options[:text]
    elsif options[:html]
      content_type "text/html"
      body options[:html]
    else
      raise "missing :text or :html options for message body"
    end 
    
    true
  end

  def to_address(email,mail_template,variables = {},queue_hash=nil) #:nodoc:
    variables = variables.clone
    variables.stringify_keys!
    
    unless mail_template.is_a?(MailTemplate)
      mail_template = MailTemplate.find(mail_template)
    end 
  
    subject     mail_template.render_subject(variables)
    recipients  email
    
    if variables['system:from']
      from variables['system:from']
    elsif variables['system:from_mail_name']
      from "\"#{variables['system:from_mail_name']}\" <#{Configuration.reply_to_email}>"
    elsif !Configuration.mailing_from.to_s.empty?
      from "\"#{Configuration.mailing_from}\" <#{Configuration.reply_to_email}>"
    else
      from Configuration.reply_to_email    
    end
    
    headers mail_template.additional_headers(variables)

    sent_on     Time.now

    attachments = variables.delete('attachments') || []
    attachments += mail_template.attachments

    if attachments.length > 0    
      
      if mail_template.body_type.include?('text') && mail_template.body_type.include?('html')
        part(:content_type => "multipart/alternative") do |p|
          p.part :content_type => 'text/plain',
            :body => mail_template.render_text(variables)
          p.part :content_type => "text/html", :transfer_encoding => '7bit',
            :body => mail_template.render_html(variables)
        end
      elsif mail_template.body_type.include?('text')
          part :content_type => 'text/plain',
            :body => mail_template.render_text(variables)
      elsif mail_template.body_type.include?('html')
          part :content_type => "text/html",
            :body => mail_template.render_html(variables)
      end
    else
      if mail_template.body_type.include?('text') && mail_template.body_type.include?('html')
        content_type "multipart/alternative"

        part :content_type => 'text/plain',
            :body => mail_template.render_text(variables)
        part :content_type => "text/html", :transfer_encoding => '7bit',
            :body => mail_template.render_html(variables)
      elsif mail_template.body_type.include?('text')
        content_type 'text/plain'
        body mail_template.render_text(variables)
      elsif mail_template.body_type.include?('html')
          content_type "text/html"
          body mail_template.render_html(variables)
      end 

    end
    
    
    if attachments.length > 0
      attachments.each do |attached_file|
        filename = attached_file.is_a?(DomainFile) ? attached_file.filename : attached_file
        attachment_name = attached_file.is_a?(DomainFile) ? attached_file.name : File.basename(attached_file)
        File.open(filename) do |file_obj|
          mime_types =  MIME::Types.type_for(filename) 
          attachment :body => file_obj.read, 
                     :filename => attachment_name, 
                     :content_type => mime_types[0].to_s || 'text/plain'
        end 
      end
    end
    
    true
  end

  # user should have  email and name
  def to_user(user,mail_template,variables = {}) #:nodoc:
    if user.is_a?(Integer)
      user = EndUser.find(user)
    end
  
    vars  = user.attributes.to_hash.merge(variables.to_hash)
    vars[:name] = user.name if user
      
    # Change language to the recipient if necessary
    language_code = Locale.language_code
    if(vars['language'])
      changed_language = false
      if Configuration.languages.include?(vars['language'])
        Locale.set(vars['language'])
        changed_language = true
      end
    end
    
    # Add in a language specific greeting
    if(vars['gender']) 
      vars['greeting'] = vars['gender'] == 'F' ? 'Dear Mrs.'.t : 'Dear Mr.'.t
      vars['title'] = vars['gender'] == 'F' ? 'Mrs.'.t : 'Mr.'.t
    end
    
    vars['introduction'] = user.introduction.t if !user.introduction.blank?
  
    # Change the language back if necessary
    if changed_language
      Locale.set(language_code)
    end

    to_address(user.email,mail_template,vars)
    
  end

  def receive(email)
    if email.content_type == 'multipart/report'

      original_message_part = email.parts.detect do |part|
	part.content_type == 'message/rfc822'
      end

      return unless original_message_part

      parsed_msg = TMail::Mail.parse(original_message_part.body)

      handler = parsed_msg.header_string('x-webiva-handler')
      domain_name = parsed_msg.header_string('x-webiva-domain')
    else
      handler = email.header_string('x-webiva-handler')
      domain_name = email.header_string('x-webiva-domain')
    end

    return unless handler && domain_name

    domain = Domain.find_by_name(domain_name)
    unless domain
      logger.error("invalid domain #{domain_name} with handler #{handler}")
      return
    end

    DomainModel.activate_domain(domain.get_info, 'production', false)

    handler_info = self.get_handler_info(:mailing, :receiver, handler)
    unless handler_info
      logger.error("invalid handler #{handler} for domain #{domain_name}") if logger
      return
    end

    handler_info[:class].receive(email)
  end
end
