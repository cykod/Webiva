# Copyright (C) 2009 Pascal Rettig.


class WizardController < CmsController
  layout "manage"
  
  before_filter :assign_steps
  
  def self.wizard_steps(steps)
      self.send :define_method, :get_steps do 
        return steps
      end    
  end
  
  
  def assign_steps
    @wizard_steps = get_steps
    @current_action = action_name
    
    
    @wizard = true
  end
  
end
