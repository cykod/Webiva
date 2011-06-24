# Copyright (C) 2009 Pascal Rettig.

class Feedback::CommentsController < ParagraphController
  
  # Editor for comments
  editor_header "Feedback Paragraphs", :paragraph_content
  
  editor_for :comments, :name => 'Comments', :feature => :comments_page_comments,
    :inputs => { :input => [[:content_identifier, 'Content ID', :content]],
                 :comments_ok => [[:comments_ok, 'Allow Commenting', :boolean]]
               },
    :triggers => [['New Comment','action']]

  editor_for :pingback_auto_discovery, :name => 'Pingback Autodiscovery Paragraph', :no_options => true

  content_model :comments

  def self.get_comments_info 
    [   {:name => 'Feedback',:url => { :controller => '/feedback' } ,:permission => 'editor_content' } ]
  end
  
  class CommentsOptions < HashModel
    attributes :allowed_to_post => 'members', :linked_to_type => 'connection', :order => 'newest', :show => 1, :captcha => false, :required_fields => [ 'name'], :save_user => false, :source => '', :user_tags => ''
    
    boolean_options :captcha, :save_user

    integer_options :show
  end
end
