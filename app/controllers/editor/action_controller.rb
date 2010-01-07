# Copyright (C) 2009 Pascal Rettig.

class Editor::ActionController < ParagraphController #:nodoc:all
  permit 'editor_editor'
  
  # Editor for authorization paragraphs
  editor_header "System Paragraphs", :paragraph_action
  editor_for :triggered_action, :name => 'Triggered Actions',  :triggers => [ ['View Page','view']]

  editor_for :html_headers, :name => 'HTML/JS/CSS Headers'

  def triggered_action
      
  end

  class HtmlHeadersOptions < HashModel
    attributes :css => nil, :javascript => nil, :html_header => nil

    def css_files
      @css_files ||= self.css.to_s.split("\n").select { |elm| !elm.blank? }.uniq
    end

    def js_files
      @js_files ||= self.javascript.to_s.split("\n").select { |elm| !elm.blank? }.uniq
    end
  end
  
end
