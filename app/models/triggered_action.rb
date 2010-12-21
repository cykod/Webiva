# Copyright (C) 2009 Pascal Rettig.


=begin rdoc
Represents a single action that will trigger. See 
Trigger::TriggeredActionHandler for more information on triggers and how to 
add your own triggers into the system.
=end
class TriggeredAction < DomainModel
  validates_presence_of :action_type,:name, :action_trigger, :trigger
  
  belongs_to :trigger, :polymorphic => true
  
  serialize :data
  
  include ActionView::Helpers::TagHelper
  
  def validate #:nodoc
    full_act = self.full_action_type
    unless TriggeredAction.available_actions_options.detect { |opt| opt[1] == full_act } 
      self.errors.add(:full_action_type,'is not a valid action')
      self.errors.add(:action_type,'is not a valid action')
    end    
  end
  
  def before_create #:nodoc:
    self.data ||= {}
  end
  
  def triggers #:nodoc:
    self.trigger.triggers
  end
  
  # Return a list of available actions
  def self.available_actions
    returning trigger_list = [] do
      get_handler_info(:trigger,:actions).each do |info|
        trigger_list.concat(info[:class].triggered_actions)
      end
    end
  end
  
  # Return a select friendly list of available actions
  def self.available_actions_options
    available_actions.map { |act| [act[:description], "#{act[:module]}:#{act[:name]}" ] }
  end
  
  # Performs this action
  def perform(data = {},user = nil,session = nil)
    triggered_action_class.session = session
    triggered_action_class.perform(data,user)
  end
  
  def options_type_name  #:nodoc:
    triggered_action_class.option_fields_name
  end

  def options_partial #:nodoc:
    triggered_action_info[:options_partial]
  end
  
  def triggered_action_info #:nodoc:
    triggered_action_module_class.triggered_action_hash[self.action_type.to_sym]
  end
  
  def triggered_action_module_class #:nodoc:
    self.action_module.classify.constantize
  end
  
  def triggered_action_class #:nodoc:
    return @triggered_action_class if @triggered_action_class
    act_class = self.action_type + "_trigger"
    cls = "#{self.action_module.classify}::#{act_class.classify}".constantize
    @triggered_action_class ||= cls.new(self)
  end

  def action_options(opts) #:nodoc:
    opts = data if opts.blank?
    act_class = self.action_type + "_trigger"
    "#{self.action_module.classify}::#{act_class.classify}::#{(self.action_type + "_options").camelcase}".constantize.new(opts)
  end
  
  
  def full_action_type #:nodoc:
    if self.action_type
      "#{self.action_module}:#{self.action_type}"
    else
      nil
    end
  end
  
  def full_action_type=(val) #:nodoc:
    vals = val.split(":")  
    self.action_module = vals[0]
    self.action_type = vals[1]
  end

end
