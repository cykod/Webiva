# Copyright (C) 2009 Pascal Rettig.

class Feedback::RatingsRenderer < ParagraphRenderer

  MAX_SESSION_RATINGS = 20
  SESSION_RATINGS_KEY = :feedback_ratings

  features '/feedback/ratings_feature'

  paragraph :ratings, :ajax => true

  def ratings
    @options = paragraph_options(:ratings)

    if editor?
      @end_user_rating = FeedbackEndUserRating.new
      @feedback_rating = @end_user_rating.feedback_rating
      @can_rate = true
      @rating_url = ajax_url
      return render_paragraph :feature => :ratings_page_ratings
    end

    content_link = nil
    if ajax?
      return render_paragraph :inline => '' unless params[:target] && params[:rating] && session[SESSION_RATINGS_KEY].has_key?(params[:target])
      content_link = session[SESSION_RATINGS_KEY][params[:target]]
    end

    connection_type, content_link = page_connection() unless content_link

    return(render_paragraph :inline => '') unless content_link

    target_type, target_id = *content_link
    display_string = "#{target_type}_#{target_id}"

    result = renderer_cache(FeedbackRating, display_string, :skip => ajax?) do |cache|
      @end_user_rating = get_end_user_rating( target_type, target_id )

      if ajax?
	@end_user_rating.rating = params[:rating]
	@end_user_rating.rated_ip = request.env['REMOTE_ADDR']
	@end_user_rating.save
      end

      @feedback_rating = @end_user_rating.feedback_rating
      @can_rate = @options.allowed_to_rate == 'all' || myself.id ? true : false
      @rating_url = ajax_url

      cache[:output] = ratings_page_ratings_feature
    end

    if ! ajax?
      require_js 'prototype.js'
    end

    render_paragraph :text => result.output
  end

  protected
  def get_end_user_rating(target_type, target_id)
    return @end_user_rating if @end_user_rating

    session[SESSION_RATINGS_KEY] ||= {}
    target_hash = FeedbackEndUserRating.target_hash(target_type, target_id)
    if session[SESSION_RATINGS_KEY].has_key?(target_hash)
      feedback_end_user_rating_id = session[SESSION_RATINGS_KEY][target_hash][2]
      if feedback_end_user_rating_id
	@end_user_rating = FeedbackEndUserRating.find_by_id( feedback_end_user_rating_id )
	return @end_user_rating if @end_user_rating
	session[SESSION_RATINGS_KEY].delete(target_hash)
      end
    end

    if myself.id
      @end_user_rating = FeedbackEndUserRating.with_target(target_type, target_id).find_by_end_user_id(myself.id)
      if @end_user_rating
	add_session_feedback_ratings(target_hash, target_type, target_id, @end_user_rating.id)
	return @end_user_rating
      end
    end

    add_session_feedback_ratings(target_hash, target_type, target_id)
    @end_user_rating = FeedbackEndUserRating.new :target_type => target_type, :target_id => target_id
    @end_user_rating.end_user_id = myself.id if myself.id
    @end_user_rating
  end

  def add_session_feedback_ratings(target_hash, target_type, target_id, feedback_end_user_rating_id=nil)
    if session[SESSION_RATINGS_KEY].size >= MAX_SESSION_RATINGS

      # if you are adding a new item or if the size is > MAX_SESSION_RATINGS remove the oldest item
      if ! session[SESSION_RATINGS_KEY].has_key?(target_hash) || session[SESSION_RATINGS_KEY].size > MAX_SESSION_RATINGS
	oldest_ratings = session[SESSION_RATINGS_KEY].sort { |a,b| a[1][3] <=> b[1][3] }

	while session[SESSION_RATINGS_KEY].size >= MAX_SESSION_RATINGS
	  session[SESSION_RATINGS_KEY].delete( oldest_ratings.shift.shift )
	end
      end
    end

    session[SESSION_RATINGS_KEY][target_hash] = [target_type, target_id, feedback_end_user_rating_id, Time.now]
  end
end
