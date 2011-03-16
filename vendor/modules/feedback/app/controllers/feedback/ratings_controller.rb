# Copyright (C) 2009 Pascal Rettig.

class Feedback::RatingsController < ParagraphController
  
  # Editor for comments
  editor_header "Feedback Paragraphs", :paragraph_content
  
  editor_for :ratings, :name => 'Ratings', :feature => :ratings_page_rating,
                       :inputs => [[ :content_identifier, 'Content ID', :content]],
                       :triggers => [['New Rating','action']]

  content_model :feedback_ratings

  def self.get_ratings_info 
    [   {:name => 'Ratings',:url => { :controller => '/feedback', :action => 'ratings' } ,:permission => 'editor_content' } ]
  end
  
  class RatingsOptions < HashModel
    attributes :allowed_to_rate => 'members', :max_stars => 5
    
    integer_options :max_stars
  end
end
