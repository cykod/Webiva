# Copyright (C) 2009 Pascal Rettig.

class Feedback::CommentsController < ParagraphController
  
  # Editor for comments
  editor_header "Content Paragraphs", :paragraph_content
  
  editor_for :comments, :name => 'Comments', :features => ['comments'],
                          :inputs => [ [ :content_identifier, 'Content ID', :content ] ],
                          :triggers => [ ['New Comment','action'] ]

  content_model :comments

  def self.get_comments_info 
    [   {:name => 'Feedback',:url => { :controller => '/feedback' } ,:permission => 'editor_content' } ]
  end
  
  def comments
    
    @options = CommentOptions.new(params[:comments] || @paragraph.data || {})
    if handle_paragraph_update(@options)
      DataCache.expire_content("Comments")
      return
    end

    
  end
  

  class CommentOptions < HashModel
    attributes :allowed_to_post => 'members', :linked_to_type => 'connection', :order => 'newest', :show => 1, :captcha => false
    
    boolean_options :captcha

    integer_options :show

  end

end
