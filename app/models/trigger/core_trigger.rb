# Copyright (C) 2009 Pascal Rettig.


# This class contains the core triggers that are available in the system
class Trigger::CoreTrigger < Trigger::TriggeredActionHandler

  def self.trigger_actions_handler_info
    { :name => 'Core Triggered Actions' }
  end  


  
  register_triggered_actions [
        { :name => :email,
          :description => 'Send an email',
          :options_partial => '/triggered_action/email'
        },
        { :name => :tag,
          :description => 'Add a tag' ,
          :options_partial => '/triggered_action/tag'
        },
        { :name => :referrer,
          :description => 'Set the user referrer',
          :options_partial => '/triggered_action/referrer'
        }
      ]

  class EmailTrigger < Trigger::TriggerBase #:nodoc:


    class EmailOptions < HashModel
      default_options :subject => nil, :custom_message => nil, :user_class => nil, :publication_id => nil, :include_user_info => 'n', :include_data => 'n', :email_to => 'user_class', :send_type => 'message', :mail_template_id => nil, :email_addresses => nil, :from_name => nil, :message_from => nil
      
      
      integer_options :mail_template_id,:user_class, :publication_id
      validates_presence_of :email_to, :send_type
      
      def validate
        if(self.send_type == 'message')
          errors.add(:subject,'is missing') if self.subject.blank?
        else
          errors.add(:mail_template_id,'is missing') if self.mail_template_id.blank?        
        end
        
        case(self.email_to)
        when 'user_class':
          errors.add(:user_class,'is missing') if self.user_class.blank?
        when 'addresses':
          errors.add(:email_addresses,'are missing') if self.email_addresses.strip.blank?
        end
          
      end
    end    
    
    options "Send Email Options", EmailOptions
    
    def perform(action_data={},user = nil)
    
      data_vars = action_data.is_a?(DomainModel) ? action_data.attributes.symbolize_keys :  (action_data.is_a?(Hash) ? action_data : {})
      data_vars = data_vars.symbolize_keys
    
      # Find out who we are emailing
      if options.email_to == 'autorespond'
        begin
          emails = [ action_data.is_a?(DomainModel) ? (action_data.attributes['email'] || action_data.attributes['email_address']) : (action_data['email']  || action_data['email_address']) ]
        rescue
          return false
        end
      elsif options.email_to == 'addresses'
        emails = options.email_addresses.split.collect { |email| DomainModel.variable_replace(email.strip,data_vars) }
      elsif options.email_to == 'user_class'
        emails = EndUser.find(:all,:conditions => ['user_class_id = ?',options.user_class]).collect { |usr| usr.email }
      end
      
      # Generate Message body - either entire message or parts
      body = options.send_type == 'message' ?  options.custom_message.to_s : ''
      if options.include_user_info == 'y' && user.is_a?(EndUser)
          body += "<br/>"
          body += user.html_description
      end
      
      if @triggered_action.trigger_type == 'ContentPublication' && options.publication_id.to_i > 0
        publication = ContentPublication.find_by_id(options.publication_id)
        if publication
          body += "<br/>" + publication.render_html(action_data)
        end
      elsif options.include_data == 'y'
        action_data = action_data.attributes if action_data.is_a?(DomainModel)
        if action_data.is_a?(Hash)
          body += "<br/><table>"
          action_data.each do |key,val|
            body += "<tr><td valign='baseline' class='label'>#{key.to_s.humanize}</td><td valign='baseline' class='data'>#{val.to_s}</td></tr>"
          end
          body += "</table>"
        end
      end
      
      if options.send_type == 'message'
        msg_options = { :html => body }
        msg_options[:from] = options.message_from unless options.message_from.blank?
        
        emails.each do |email|
          MailTemplateMailer.deliver_message_to_address(email,options.subject,msg_options)
        end    
      elsif options.send_type == 'template'
        action_data = action_data.attributes if action_data.is_a?(DomainModel)
        variables = action_data.clone
        variables.stringify_keys!
        variables['DATA'] = body
        
        mail_template  = MailTemplate.find_by_id(options.mail_template_id)
        variables['system:from'] = DomainModel.variable_replace(options.message_from,data_vars) unless options.message_from.blank?
        emails.each do |email|
          MailTemplateMailer.deliver_to_address(email,mail_template,variables)
        end
      end
    end    
      
  end
  
  class TagTrigger < Trigger::TriggerBase #:nodoc:

      
    class TagOptions < HashModel
      default_options :tags => nil
      validates_presence_of :tags
    end
    
    options "Tag Options", TagOptions

    def perform(data={},user = nil)
      if user
        user.tag_names_add(options.tags)
      end
    end    
  end
  
  class ReferrerTrigger < Trigger::TriggerBase #:nodoc:
  
    class ReferrerOptions < HashModel
      default_options :referrer => nil, :apply => 'unregistered'
      validates_presence_of :referrer
    end
    
    options "Referrer Options", ReferrerOptions
  
    def perform(data={},user = nil)
      if user && (options.apply == 'all' || !user.id)
        user.referrer = options.referrer
        user.save if user.id # only save if the user exists
      end
    end    
  end
  
  
  
      
end

