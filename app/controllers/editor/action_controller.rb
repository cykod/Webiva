# Copyright (C) 2009 Pascal Rettig.

class Editor::ActionController < ParagraphController
  permit 'editor_editor'
  
  # Editor for authorization paragraphs
  editor_header "Action Paragraphs", :paragraph_action
  editor_for :triggered_action, :name => 'Triggered Actions',  :triggers => [ ['View Page','view']]

  def triggered_action
      
  end


  
end
