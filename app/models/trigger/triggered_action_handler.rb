# Copyright (C) 2009 Pascal Rettig.


=begin rdoc
To add new triggered actions into the system, register a of type :trigger, :actions in your AdminController

Then subclass Trigger::TriggeredActionHandler, call register_triggered_actions and define the appropriate
trigger classes (subclassing Trigger::TriggerBase) for each trigger. See app/models/trigger/core_trigger.rb for more information.
=end
class Trigger::TriggeredActionHandler


  # Register an array of triggered actions, each of which should
  # be a hash with a :name, :description and :options_partial key
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
