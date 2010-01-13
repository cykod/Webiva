
class Feedback::FeedbackWidget < Dashboard::WidgetBase

  widget :comments, :name => "Feedback: Display Recent Comments", :title => "Recent Comments", :permission => :feedback_editor


  

  def comments

    if request.post? && params[:comment_id]
      @comment =Comment.find_by_id(params[:comment_id])
      if(@comment)
        @comment.update_attributes(:rating => params[:rating])
        @rated_comment = @comment.id
      end
    end
    
    conditions = { }
    if !options.show_rating.blank?
      conditions[:rating] = options.show_rating
    end

    @comments = Comment.find(:all, :include => :end_user, :order => 'posted_at DESC', :conditions => conditions)

    render_widget :partial => '/feedback/feedback_widget/comments', :locals => { :comments => @comments, :rated_comment => @rated_comment }
  end
  
  class CommentsOptions < HashModel
    attributes :show_rating => nil,:count => 10

    integer_options :count
    validates_numericality_of :count

    options_form(
                 fld(:show_rating, :radio_buttons, :options => :available_ratings),
                 fld(:count, :text_field)
                 )
    def available_ratings
      [['All',''],['Unrated','0'],['Accepted','1'],['Rejected','-1']]
    end
  end
end
