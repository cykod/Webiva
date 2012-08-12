class LookingFor::PageRenderer < ParagraphRenderer

  features '/looking_for/page_feature'

  paragraph :view
  
  def view
    @options = paragraph_options(:view)
    @location_options = LookingForLocation.all.collect{|s| [s.to_s, s.id] }
    @locations = []
    @locations << LookingForLocation.find(@options.location_1) unless @options.location_1.blank? 
    @locations << LookingForLocation.find(@options.location_2) unless @options.location_2.blank?
    @locations << LookingForLocation.find(@options.location_3) unless @options.location_3.blank?
    
    render_paragraph :feature => :looking_for_page_view
  end

end
