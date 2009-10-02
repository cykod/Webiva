# Copyright (C) 2009 Pascal Rettig.

class Content::CorePublication::AdminListPublication < Content::CorePublication::ListPublication
  # All the same options as the list publication
  
  register_triggers :view, :delete    
end


