require 'digest/md5'

class FeedbackEndUserRating < DomainModel
  belongs_to :target, :polymorphic => true
  belongs_to :end_user

  validates_presence_of :target_type, :target_id, :rating

  validates_numericality_of :rating, :only_integer => true

  def self.with_target(type, id); self.where('feedback_end_user_ratings.target_type = ? and feedback_end_user_ratings.target_id = ?', type, id); end

  cached_content :update => [:feedback_rating]

  before_save :update_rated_at
  after_create :update_feedback_rating
  after_update :change_feedback_rating
  after_destroy :remove_feedback_rating

  def update_rated_at
    self.rated_at = Time.now if self.rated_at.blank?
  end

  # if for_updating is set to true then it is possible for feedback_rating to return nil if it updates itself
  def feedback_rating(for_updating=false)
    return @feedback_rating if @feedback_rating && (@feedback_rating.id || for_updating == false)

    feedback_ratings = FeedbackRating.with_target(self.target_type, self.target_id).find(:all, :order => '`feedback_ratings`.id DESC')
    if feedback_ratings.nil? || feedback_ratings.size == 0
      @feedback_rating = FeedbackRating.new
      @feedback_rating.target_type = self.target_type
      @feedback_rating.target_id = self.target_id
      @feedback_rating.save if for_updating
      @feedback_rating
    elsif feedback_ratings.size > 1
      @feedback_rating = feedback_ratings.shift
      feedback_ratings.collect { |r| r.destroy }
      @feedback_rating.rating_sum = FeedbackEndUserRating.with_target(self.target_type, self.target_id).sum(:rating)
      @feedback_rating.rating_count = FeedbackEndUserRating.with_target(self.target_type, self.target_id).count()
      @feedback_rating.save
      for_updating ? nil : @feedback_rating
    else
      @feedback_rating = feedback_ratings[0]
    end
  end

  def target_hash
    return @target_hash if @target_hash
    @target_hash = self.class.target_hash(self.target_type, self.target_id)
  end

  def self.target_hash(target_type, target_id)
    md5 = Digest::MD5.new
    md5 << "#{target_type}_#{target_id}"
    md5.hexdigest
  end

  def update_feedback_rating
    self.feedback_rating.update_rating(self.rating) if self.feedback_rating(true)
  end

  def change_feedback_rating
    if self.rating_changed?
      diff = self.rating - changed_attributes['rating']
      self.feedback_rating.update_rating(diff, 0) if self.feedback_rating(true)
    end
  end

  def remove_feedback_rating
    self.feedback_rating.update_rating(-self.rating, -1) if self.feedback_rating(true)
  end
end
