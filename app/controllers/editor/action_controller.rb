# Copyright (C) 2009 Pascal Rettig.

class Editor::ActionController < ParagraphController
  permit 'editor_editor'
  
  # Editor for authorization paragraphs
  editor_header "System Paragraphs", :paragraph_action
  editor_for :triggered_action, :name => 'Triggered Actions',  :triggers => [ ['View Page','view']]

  editor_for :html_headers, :name => 'HTML/JS/CSS Headers'

  def triggered_action
      
  end

  class HtmlHeadersOptions < HashModel
    attributes :css => nil, :javascript => nil, :html_header => nil

    def validate
      css_files.each do |file|
        if(file =~ /^images\/(.*)$/)
          df = DomainFile.find_by_file_path("/#{$1}")
          if !df 
            self.errors.add(:css,'is an invalid file manager file:' + $1)
          end
        end
      end

      js_files.each do |file|
        if(file =~ /^images\/(.*)$/)
          df = DomainFile.find_by_file_path("/#{$1}")
          if !df
            self.errors.add(:javascript,'is an invalid file manager file:' + $1)
          end
        end
      end

    end
  end
  
end
