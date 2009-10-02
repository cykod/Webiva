# Copyright (C) 2009 Pascal Rettig.

class TriggeredAction < DomainModel
  validates_presence_of :action_type,:name, :action_trigger, :trigger
  
  belongs_to :trigger, :polymorphic => true
  
  serialize :data
  
  include ActionView::Helpers::TagHelper
  
  def validate
    full_act = self.full_action_type
    unless TriggeredAction.available_actions_options.detect { |opt| opt[1] == full_act } 
      self.errors.add(:full_action_type,'is not a valid action')
      self.errors.add(:action_type,'is not a valid action')
    end    
  end
  
  def before_create
    self.data ||= {}
  end
  
  def triggers
    self.trigger.triggers
  end
  
  def self.available_actions
    returning trigger_list = [] do
      get_handler_info(:trigger,:actions).each do |info|
        trigger_list.concat(info[:class].triggered_actions)
      end
    end
  end
  
  def self.available_actions_options
    available_actions.map { |act| [act[:description], "#{act[:module]}:#{act[:name]}" ] }
  end
  
  
  def perform(data = {},user = nil)
    triggered_action_class.perform(data,user)
  end
  
  def options_type_name 
    triggered_action_class.option_fields_name
  end

  def options_partial
    triggered_action_info[:options_partial]
  end
  
  def triggered_action_info
    triggered_action_module_class.triggered_action_hash[self.action_type.to_sym]
  end
  
  def triggered_action_module_class
    self.action_module.classify.constantize
  end
  
  def triggered_action_class
    return @triggered_action_class if @triggered_action_class
    act_class = self.action_type + "_trigger"
    cls = "#{self.action_module.classify}::#{act_class.classify}".constantize
    @triggered_action_class ||= cls.new(self)
  end  
  
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
    
    def name
      'Send Email Options'
    end
  end     
  
  def perform_email(action_data={},user = nil)
    options = EmailOptions.new(self.data)
    
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
    
    if trigger_type == 'ContentPublication' && options.publication_id.to_i > 0
      publication = ContentPublication.find_by_id(options.publication_id)
      if publication
        body += "<br/>" + render_publication_view(publication,action_data)
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
  
  def full_action_type
    if self.action_type
      "#{self.action_module}:#{self.action_type}"
    else
      nil
    end
  end
  
  def full_action_type=(val)
    vals = val.split(":")  
    self.action_module = vals[0]
    self.action_type = vals[1]
  end

end
