
class FeedbackRating < DomainModel
  belongs_to :target, :polymorphic => true

  validates_presence_of :target_type, :target_id

  cached_content :identifier => :target_identifier

  named_scope :with_target, lambda { |type, id| {:conditions => ['`feedback_ratings`.target_type = ? and `feedback_ratings`.target_id = ?', type, id]} }

  def target_identifier
    "#{self.target_type}_#{self.target_id}"
  end

  def rating
    return @rating if @rating
    @rating = self.rating_count > 0 ? self.rating_sum / self.rating_count : nil
  end

  def update_rating(user_rating, count=1)
    self.class.update_rating( self.id, user_rating, count )
    self.rating_sum += user_rating
    self.rating_count += count
    @rating = nil
  end

  def self.update_rating(id, user_rating, count)
    connection.update( sanitize_sql_array(["update feedback_ratings set rating_sum = rating_sum + ?, rating_count = rating_count + ? where id = ?", user_rating, count, id]) )
  end
end
