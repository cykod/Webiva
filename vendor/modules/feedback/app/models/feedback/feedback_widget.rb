
class Feedback::FeedbackWidget < Dashboard::WidgetBase

  widget :comments, :name => "Feedback: Display Recent Comments", :title => "Recent Comments", :permission => :feedback_editor
  widget :pingbacks, :name => 'Pingback: Display Recent Pingbacks', :title => 'Recent Pingbacks', :permission => :feedback_editor

  def comments

    if request.post? && params[:comment_id]
      @comment =Comment.find_by_id(params[:comment_id])
      if(@comment)
        @comment.update_attributes(:rating => params[:rating])
        @rated_comment = @comment.id
      end
    end
    
    set_icon 'feedback_icon.png'
    set_title_link url_for(:controller => 'feedback/feedback')
    conditions = { }
    if !options.show_rating.blank?
      conditions[:rating] = options.show_rating
    end

    @comments = Comment.find(:all, :include => :end_user, :order => 'posted_at DESC', :conditions => conditions, :limit => options.count)

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

  def pingbacks

    if request.post? && params[:pingback_id] && params[:action]
      @pingback = FeedbackPingback.find_by_id params[:pingback_id]
      case params[:pingback_action]
      when 'delete'
	@pingback.destroy
      when 'create'
	@pingback.create_comment myself
      when 'remove'
	Comment.destroy_all("source_type = 'FeedbackPingback' and source_id = #{@pingback.id}")
	@pingback.update_attributes :has_comment => false
      end
    end

    set_icon 'feedback_icon.png'
    set_title_link url_for(:controller => '/feedback/manage_pingbacks')

    conditions = { }
    if ! options.show_accepted
      conditions[:has_comment] = false
    end

    @pingbacks = FeedbackPingback.find(:all, :order => 'posted_at DESC', :conditions => conditions, :limit => options.count)

    render_widget :partial => '/feedback/feedback_widget/pingbacks', :locals => { :pingbacks => @pingbacks, :selected_pingback => @pingback, :applied_action => params[:action] }
  end

  class PingbacksOptions < HashModel
    attributes :show_accepted => false, :count => 10

    boolean_options :show_accepted
    integer_options :count
    validates_numericality_of :count

    options_form(
                 fld(:show_accepted, :check_box),
                 fld(:count, :text_field)
                 )
  end
end
