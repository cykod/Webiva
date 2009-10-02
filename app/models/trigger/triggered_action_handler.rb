# Copyright (C) 2009 Pascal Rettig.


class Trigger::TriggeredActionHandler


  def self.register_triggered_actions(types)
  
   module_name = self.to_s.underscore

    # Add in the module name    
    types.each { |type| type[:module] = module_name }
    
    # Create the fields class method
    cls = class << self; self; end
    cls.send(:define_method,:triggered_actions) do
      types
    end
    
    # Generate the Hash
    type_hash_info = types.index_by { |type| type[:name] }
    
    # Generate the Hash class method
    cls.send(:define_method,:triggered_action_hash) do
      type_hash_info
    end
  
  end



end
