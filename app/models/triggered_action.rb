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

  def action_options(opts)
    opts = data if opts.blank?
    act_class = self.action_type + "_trigger"
    "#{self.action_module.classify}::#{act_class.classify}::#{(self.action_type + "_options").camelcase}".constantize.new(opts)
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
