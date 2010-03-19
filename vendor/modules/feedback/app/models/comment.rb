# Copyright (C) 2009 Pascal Rettig.

class Comment < DomainModel

  include WebivaCaptcha::ModelSupport

  belongs_to :target, :polymorphic => true
  belongs_to :source, :polymorphic => true
  
  has_end_user :end_user_id, :name_column => :name

  belongs_to :rated_by_user, :foreign_key => 'rated_by_user_id', :class_name => 'EndUser'

  cached_content

  safe_content_filter({ :comment => :comment_html},:filter => :comment)

  validates_presence_of :name, :comment, :target_type, :target_id
  
  named_scope :with_rating, lambda { |r| {:conditions => ['`comments`.rating >= ?', r]} }
  named_scope :for_target, lambda { |type, id| {:conditions => ['`comments`.target_type = ? AND `comments`.target_id = ?', type, id]} }
  named_scope :order_by_posted, lambda { |order| order == 'newest' ? {:order => '`comments`.posted_at DESC'} : {:order => '`comments`.posted_at'} }
  named_scope :for_source, lambda { |type, id| {:conditions => ['`comments`.source_type = ? AND `comments`.source_id = ?', type, id]} }

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
    if self.name.nil?
      self.name = self.end_user ? self.end_user.name : 'Anonymous'.t
    end
  end

  def before_save
    self.posted_at = Time.now if self.posted_at.blank?
  end
end
