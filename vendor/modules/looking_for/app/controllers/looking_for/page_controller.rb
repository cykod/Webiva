class LookingFor::PageController < ParagraphController

  editor_header 'Looking For Paragraphs'
  
  editor_for :view, :name => "View", :feature => :looking_for_page_view

  class ViewOptions < HashModel
    attributes :title => "", 
               :location_1 => nil,
               :location_2 => nil,
               :location_3 => nil
    validates_presence_of :title
  end

end
