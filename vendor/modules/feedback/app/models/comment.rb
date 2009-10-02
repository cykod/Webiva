# Copyright (C) 2009 Pascal Rettig.

class Comment < DomainModel

  belongs_to :target, :polymorphic => true
  
  belongs_to :end_user

  belongs_to :rated_by_user, :foreign_key => 'rated_by_user_id', :class_name => 'EndUser'
  
  validates_presence_of :name, :comment
  
  attr_accessor :captcha_invalid


  def validate
    errors.add_to_base("Captcha is invalid") if self.captcha_invalid
  end
  
  def rating_icon
    if rating == 0
      'icons/table_actions/rating_none.gif'
    elsif rating > 0
      'icons/table_actions/rating_positive.gif'
    else 
      'icons/table_actions/rating_negative.gif'
    end

  end
  
  def before_save
    self.posted_at = Time.now if self.posted_at.blank?
  end
end
