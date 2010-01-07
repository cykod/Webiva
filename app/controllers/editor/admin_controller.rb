# Copyright (C) 2009 Pascal Rettig.

class Editor::AdminController < ModuleController #:nodoc:all
  permit 'editor'
  
  layout nil
  # These modules are always active
  skip_before_filter :validate_module
  
  component_info 'editor', :description => 'Built In Editor Modules', 
                              :access => :public

  
  content_node_type "Static Pages", "SiteNode",  :search => true, :editable => false
end
