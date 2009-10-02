# Copyright (C) 2009 Pascal Rettig.

class ModuleParagraph

  attr_reader :id,:zone_idx,:position,:display_module,:site_module,:display_type,:feature,:name,:display_body,:data
  
  attr_accessor :params
  attr_accessor :rendered_output
  
  def initialize(*args) 
    @id = args[0] || nil
    @zone_idx = args[1].to_i || nil
    @position = args[2].to_i || nil
    @display_module = args[3] || nil
    @site_module = args[4] || nil
    @display_type = args[5] || nil
    @feature = args[6] || nil
    @name = args[7] || nil
    @display_body = args[8] || nil
    @data = args[9] || nil
    
    @params = {}
  end 
  
end
