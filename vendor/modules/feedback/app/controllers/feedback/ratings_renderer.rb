# Copyright (C) 2009 Pascal Rettig.

class Feedback::RatingsRenderer < ParagraphRenderer

  features '/feedback/ratings_feature'

  paragraph :ratings, :ajax => true

  def ratings
    @options = paragraph_options(:ratings)

    @feedback_session = create_feedback_session

    if editor?
      @end_user_rating = FeedbackEndUserRating.new
      @feedback_rating = @end_user_rating.feedback_rating
      @can_rate = true
      @rating_url = ajax_url
      return render_paragraph :feature => :ratings_page_ratings
    end

    content_link = nil
    if ajax?
      return render_paragraph :inline => '' unless can_rate? && params[:target] && params[:rating] && valid_rating?(params[:rating]) && @feedback_session.has?(params[:target])
      content_link = @feedback_session.get_target(params[:target])
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
	@end_user_rating.rated_at = Time.now
	@end_user_rating.save
      end

      @feedback_rating = @end_user_rating.feedback_rating
      @can_rate = can_rate?
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

    target_hash = FeedbackEndUserRating.target_hash(target_type, target_id)

    if @feedback_session.has?(target_hash)
      feedback_end_user_rating_id = @feedback_session.get_feedback_end_user_rating_id(target_hash)

      if feedback_end_user_rating_id
	# in a rare situation where the admin removed a user's rating, just remove the rating from the session and continue
	@end_user_rating = FeedbackEndUserRating.find_by_id( feedback_end_user_rating_id )
	return @end_user_rating if @end_user_rating
	@feedback_session.delete(target_hash)
      end
    end

    if myself.id
      @end_user_rating = FeedbackEndUserRating.with_target(target_type, target_id).find_by_end_user_id(myself.id)
      if @end_user_rating
	@feedback_session.add(target_hash, target_type, target_id, @end_user_rating.id)
	return @end_user_rating
      end
    end

    @feedback_session.add(target_hash, target_type, target_id)

    @end_user_rating = FeedbackEndUserRating.new :target_type => target_type, :target_id => target_id
    @end_user_rating.end_user_id = myself.id if myself.id
    @end_user_rating
  end

  def can_rate?
    @can_rate ||= @options.allowed_to_rate == 'all' || myself.id ? true : false
  end

  def valid_rating?(rating)
    rating.to_i <= @options.max_stars && rating.to_i >= 0
  end

  class FeedbackSession
    MAX_SESSION_RATINGS = 20
    SESSION_RATINGS_KEY = :feedback_ratings

    def initialize(session)
      @session = session
      @session[SESSION_RATINGS_KEY] ||= []
    end

    def has?(target_hash)
      @session[SESSION_RATINGS_KEY].any? { |ele| ele[0] == target_hash }
    end

    def add(target_hash, target_type, target_id, feedback_end_user_rating_id=nil)
      delete(target_hash)

      @session[SESSION_RATINGS_KEY].unshift( [target_hash, target_type, target_id, feedback_end_user_rating_id] )

      @session[SESSION_RATINGS_KEY].slice!( MAX_SESSION_RATINGS - size ) if size > MAX_SESSION_RATINGS
    end

    def size
      @session[SESSION_RATINGS_KEY].size
    end

    def delete(target_hash)
      @session[SESSION_RATINGS_KEY].reject! { |ele| ele[0] == target_hash }
      @target = nil
    end

    def get(target_hash)
      return @target if @target && @target[0] == target_hash
      @target = @session[SESSION_RATINGS_KEY].assoc(target_hash)
    end

    def get_target(target_hash)
      data = get(target_hash)
      return nil if data.nil?
      data[1, 2]
    end

    def get_feedback_end_user_rating_id(target_hash)
      data = get(target_hash)
      return nil if data.nil?
      data[3]
    end
  end

  private
  def create_feedback_session
    @feedback_session = FeedbackSession.new session
  end
end
