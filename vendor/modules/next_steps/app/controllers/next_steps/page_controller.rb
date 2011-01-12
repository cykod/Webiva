class NextSteps::PageController < ParagraphController

  editor_header 'Next Steps Paragraphs'
  
  editor_for :view, :name => "View", :feature => :next_steps_page_view

  class ViewOptions < HashModel

  end

end
