# Copyright (C) 2009 Pascal Rettig.

class Comment < DomainModel

  belongs_to :target, :polymorphic => true
  belongs_to :source, :polymorphic => true
  
  belongs_to :end_user

  belongs_to :rated_by_user, :foreign_key => 'rated_by_user_id', :class_name => 'EndUser'

  cached_content

  safe_content_filter({ :comment => :comment_html},:filter => :comment)

  validates_presence_of :name, :comment, :target_type, :target_id
  
  attr_accessor :captcha_invalid

  named_scope :with_rating, lambda { |r| {:conditions => ['`comments`.rating >= ?', r]} }
  named_scope :for_target, lambda { |type, id| {:conditions => ['`comments`.target_type = ? AND `comments`.target_id = ?', type, id]} }
  named_scope :order_by_posted, lambda { |order| order == 'newest' ? {:order => '`comments`.posted_at DESC'} : {:order => '`comments`.posted_at'} }
  named_scope :for_source, lambda { |type, id| {:conditions => ['`comments`.source_type = ? AND `comments`.source_id = ?', type, id]} }

  def validate
    errors.add_to_base("Captcha is invalid") if self.captcha_invalid
  end
  
  def rating_icon(override=nil)
    override = rating unless override
    if override == 0
      'icons/table_actions/rating_none.gif'
    elsif override > 0
      'icons/table_actions/rating_positive.gif'
    else 
      'icons/table_actions/rating_negative.gif'
    end
  end

  def before_validation_on_create
    if self.name.nil? && self.end_user
      self.name = self.end_user.name
    end
  end

  def before_save
    self.posted_at = Time.now if self.posted_at.blank?
  end
end
