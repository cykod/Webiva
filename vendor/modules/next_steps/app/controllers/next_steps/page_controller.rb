class NextSteps::PageController < ParagraphController

  editor_header 'Next Steps Paragraphs'
  
  editor_for :view, :name => "View", :feature => :next_steps_page_view

  class ViewOptions < HashModel
    attributes :title => "", 
               :step_1 => nil,
               :step_2 => nil,
               :step_3 => nil
    validates_presence_of :title
  end

end
