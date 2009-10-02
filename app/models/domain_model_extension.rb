# Copyright (C) 2009 Pascal Rettig.



class DomainModelExtension

 def initialize(handler)
  @options = handler[1]
 end
 
 attr_reader :options

end
