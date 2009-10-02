# Copyright (C) 2009 Pascal Rettig.



class Trigger::TriggerBase 

  def initialize(ta)
    @triggered_action = ta
  end
  
  def option_class; HashModel; end
  
  def options(val=nil)
    option_class.new(val || @triggered_action.data || {})
  end
  
  def self.options(opt_name,opt_class)
    opt_class = opt_class.constantize if opt_class.is_a?(String)
    
    define_method(:option_class) { opt_class }
    define_method(:option_fields_name) { opt_name }
  end

end
