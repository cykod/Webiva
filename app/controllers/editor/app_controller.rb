# Copyright (C) 2009 Pascal Rettig.

class Editor::AppController < ParagraphController #:nodoc:all
  permit 'editor'
  
  # Editor for authorization paragraphs
  editor_header "System Paragraphs", :paragraph_app
  editor_for :module_application, :name => 'Module Application'

  def module_application
    @options = ModuleApplicationOptions.new(params[:module_application] || @paragraph.data)
    return if handle_paragraph_update(@options)
  end

  class ModuleApplicationOptions < HashModel
      default_options :application_name=> ""
      
      validates_presence_of :application_name
  end
  
end
