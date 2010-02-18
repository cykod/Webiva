# Copyright (C) 2009 Pascal Rettig.

class Feedback::CommentsController < ParagraphController
  
  # Editor for comments
  editor_header "Feedback Paragraphs", :paragraph_content
  
  editor_for :comments, :name => 'Comments', :feature => :comments_page_comments,
                        :inputs => [[ :content_identifier, 'Content ID', :content]],
                        :triggers => [['New Comment','action']]

  editor_for :pingback_auto_discovery, :name => 'Pingback Autodiscovery Paragraph', :no_options => true

  content_model :comments

  def self.get_comments_info 
    [   {:name => 'Feedback',:url => { :controller => '/feedback' } ,:permission => 'editor_content' } ]
  end
  
  class CommentsOptions < HashModel
    attributes :allowed_to_post => 'members', :linked_to_type => 'connection', :order => 'newest', :show => 1, :captcha => false
    
    boolean_options :captcha

    integer_options :show
  end
end
