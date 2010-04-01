# Copyright (C) 2009 Pascal Rettig.

class Editor::ActionRenderer < ParagraphRenderer #:nodoc:all

  paragraph :triggered_action
  paragraph :html_headers, :cache => true

  def triggered_action

    if !editor? && paragraph.view_action_count > 0
        paragraph.run_triggered_actions(myself,'view',myself)
    end
  
    if editor?
      render_paragraph :text => '[Triggered Actions]'
    else
      render_paragraph :nothing => true
    end
  end

  def html_headers

    @options = paragraph_options(:html_headers)

    if !editor?
      @options.css_files.each do |file|
        if(file =~ /^images\/(.*)$/)
          df = DomainFile.find_by_file_path("/#{$1}")
          file = df.url if df
        end
        require_css(file)
      end

      @options.js_files.each do |file|
        if(file =~ /^images\/(.*)$/)
          df = DomainFile.find_by_file_path("/#{$1}")
          file = df.url if df
        end
        require_js(file)
      end

      if !@options.html_header.blank?
        include_in_head(@options.html_header)
      end
    end

    render_paragraph :nothing => true

  end

 
end
