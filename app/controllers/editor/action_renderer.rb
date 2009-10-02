# Copyright (C) 2009 Pascal Rettig.

class Editor::ActionRenderer < ParagraphRenderer

  paragraph :triggered_action

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

end
