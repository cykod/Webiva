# Copyright (C) 2009 Pascal Rettig.

require 'mime/types'


# MailTemplateMailer is used to send MailTemplate's
# 
# See MailTemplate for a more detailed description, 
# MailTemplate#to_user and MailTemplate#to_address
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
  #     MailTemplateMailer.message_to_address(
  #                    'test@domain.com',
  #                    "This is the email subject",
  #                    :text => 'Text body',
  #                    :html => "<b>Html Body!</b>",
  #                    :from => 'Svend@karlson.com').deliver
  #
  # Either :text or :html (or both) must be specified,
  # :from is optional and will use the default or the
  # Configuration reply to email
  def message_to_address(email, subj, options ={})
    raise "missing email content" if options[:text].blank? && options[:html].blank?

    mail(:to => email, :subject => subj, :from => get_from_address(options)) do |format|
      format.text { render :text => options[:text] } if options[:text]
      format.html { render :text => options[:html] } if options[:html]
    end
  end

  def to_address(email, mail_template, variables={}, queue_hash=nil) #:nodoc:
    variables = variables.clone
    variables.stringify_keys!
    
    unless mail_template.is_a?(MailTemplate)
      mail_template = MailTemplate.find(mail_template)
    end 
  
    raise "missing email content" unless mail_template.body_type.include?('text') || mail_template.body_type.include?('html')
    
    ((variables.delete('attachments') || []) + mail_template.attachments).each do |file|
      file = file.is_a?(DomainFile) ? file.filename : file
      name = File.basename(file)
      mime_types =  MIME::Types.type_for(file)
      content_type = mime_types[0].to_s || 'text/plain'
      attachments[name] = { :content => File.read(file), :content_type => content_type }
    end

    headers mail_template.additional_headers(variables)
    
    mail(:to => email, :subject => mail_template.render_subject(variables), :from => get_from_address(variables)) do |format|
      format.text { render :text => mail_template.render_text(variables) } if mail_template.body_type.include?('text')
      format.html { render :text => mail_template.render_html(variables) } if mail_template.body_type.include?('html')
    end
  end

  # user should have  email and name
  def to_user(user,mail_template,variables = {}) #:nodoc:
    if user.is_a?(Integer)
      user = EndUser.find(user)
    end
  
    vars = user.attributes.to_hash.merge(variables.to_hash)
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
    if email.delivery_status_report?

      parsed_msg = Mail::Message.new(email.body.to_s.gsub("#{email.boundary}\n", ''))
      return unless parsed_msg

      parsed_msg = Mail::Message.new(parsed_msg.body.to_s)

      handler = parsed_msg.header['X-Webiva-Handler'].to_s.to_s
      domain_name = parsed_msg.header['X-Webiva-Domain'].to_s.to_s
    else
      handler = email.header['X-Webiva-Handler'].to_s.to_s
      domain_name = email.header['X-Webiva-Domain'].to_s.to_s
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
  
  protected
  
  def get_from_address(options={})
    if options[:from]
      options[:from]
    elsif options['system:from']
      options['system:from']
    elsif options['system:from_mail_name']
      "\"#{options['system:from_mail_name']}\" <#{Configuration.reply_to_email}>"
    elsif ! Configuration.mailing_from.to_s.empty?
      "\"#{Configuration.mailing_from}\" <#{Configuration.reply_to_email}>"
    else
      Configuration.reply_to_email    
    end
  end
end
