# Copyright (C) 2009 Pascal Rettig.


# Base class for adding new triggers into the system. See Trigger::CoreTrigger for an example
# and  Trigger::TriggeredActionHandler for more information
class Trigger::TriggerBase 

  attr_accessor :session

  def initialize(ta) #:nodoc:
    @triggered_action = ta
  end
  
  def option_class #:nodoc:
    HashModel
  end
  
  # Returns the options object for this trigger
  def options(val=nil) 
    option_class.new(val || @triggered_action.data || {})
  end
  
  def self.options(opt_name,opt_class) #:nodoc:
    opt_class = opt_class.constantize if opt_class.is_a?(String)
    
    define_method(:option_class) { opt_class }
    define_method(:option_fields_name) { opt_name }
  end

end
