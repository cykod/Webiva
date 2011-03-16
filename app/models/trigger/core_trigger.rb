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
        },
        { :name => :post_back,
          :description => 'Setup a Post Back',
          :options_partial => '/triggered_action/post_back'
        },
        { :name => :experiment,
          :description => 'Experiment conversion',
          :options_partial => '/triggered_action/experiment'
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
    
      data_vars = action_data.is_a?(DomainModel) ? action_data.triggered_attributes :  (action_data.is_a?(Hash) ? action_data : (action_data.respond_to?(:to_hash) ? action_data.to_hash : {}))
      data_vars.symbolize_keys!
    
      # Find out who we are emailing
      if options.email_to == 'autorespond'
        begin
          emails = user && ! user.email.blank? ? [user.email] : [(data_vars[:email]  || data_vars[:email_address])]
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
        action_data = action_data.triggered_attributes if action_data.is_a?(DomainModel)
        if action_data.is_a?(Hash)
          body += "<br/><table>"
          action_data.each do |key,val|
            body += "<tr><td valign='baseline' class='label'>#{key.to_s.humanize}</td><td valign='baseline' class='data'>#{val.to_s}</td></tr>"
          end
          body += "</table>"
        end
      end

      emails.reject! { |e| e.blank? }

      if options.send_type == 'message'
        msg_options = { :html => body }
        msg_options[:from] = DomainModel.variable_replace(options.message_from,data_vars) unless options.message_from.blank?
        
        emails.each do |email|
          MailTemplateMailer.deliver_message_to_address(email,options.subject,msg_options)
        end    
      elsif options.send_type == 'template'
        action_data = action_data.triggered_attributes if action_data.is_a?(DomainModel)
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
  
  class PostBackTrigger < Trigger::TriggerBase
    class PostBackOptions < HashModel
      attributes :url => nil, :format => 'params'

      validates_presence_of :url
      validates_presence_of :format
      validates_urlness_of :url
    end

    options 'Post Back Options', PostBackOptions

    def perform(data={}, user=nil)
      data = data.attributes if data.is_a?(DomainModel)
      data['user'] = user.attributes.slice('id', 'first_name', 'last_name', 'email') if user && user.id
      body = nil
      content_type = nil
      case options.format
      when 'xml'
        body = data.to_xml
        content_type = 'application/xml'
      when 'json'
        body = data.to_json
        content_type = 'application/json'
      else
        body = data.to_params
        content_type = 'application/x-www-form-urlencoded'
      end

      uri = URI.parse(options.url)
      Net::HTTP.start(uri.host, uri.port) do |http|
        path = uri.path
        path += '?' + uri.query if uri.query
        http.request_post(path, body, 'Content-Type' => content_type)
      end
    end
  end

  class ExperimentTrigger < Trigger::TriggerBase
    class ExperimentOptions < HashModel
      attributes :experiment_id => nil
      validates_presence_of :experiment_id

      options_form(
                   fld(:experiment_id, :select, :options => :experiment_options)
                   )

      def experiment_options
        Experiment.select_options_with_nil
      end
    end

    options 'Experiment Options', ExperimentOptions

    def perform(data={}, user=nil)
      return unless self.session
      Experiment.success! options.experiment_id, self.session
    end
  end
end

