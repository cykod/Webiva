class NextSteps::PageRenderer < ParagraphRenderer

  features '/next_steps/page_feature'

  paragraph :view
  
  def view
    @options = paragraph_options(:view)
    @step_options = NextStepsStep.all.collect{|s| [s.to_s, s.id] }
    @steps = []
    @steps << NextStepsStep.find(@options.step_1) unless @options.step_1.blank? 
    @steps << NextStepsStep.find(@options.step_2) unless @options.step_2.blank?
    @steps << NextStepsStep.find(@options.step_3) unless @options.step_3.blank?
    render_paragraph :feature => :next_steps_page_view
  end

end
