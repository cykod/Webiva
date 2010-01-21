# Copyright (C) 2009 Pascal Rettig.

class Editor::AppRenderer < ParagraphRenderer #:nodoc:all

  paragraph :module_application

  def module_application
    render_paragraph :text => "Module Application Paragraph"
  end

end
