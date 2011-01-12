class NextSteps::PageRenderer < ParagraphRenderer

  features '/next_steps/page_feature'

  paragraph :view

  def view

    # Any instance variables will be sent in the data hash to the 
    # next_steps_page_view_feature automatically
  
    render_paragraph :feature => :next_steps_page_view
  end

end
