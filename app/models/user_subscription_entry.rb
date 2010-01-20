# Copyright (C) 2009 Pascal Rettig.

class UserSubscriptionEntry < DomainModel
  validates_presence_of :user_subscription_id
  validates_numericality_of :user_subscription_id
  
  belongs_to :user_subscription
  
  belongs_to :end_user
  
  has_options :subscription_type, [[ 'Adminstrator Signup', 'admin'], ['Direct Signup','direct' ], ['Trigger Signup','trigger']]
  
  def email
    if self.end_user
      self.end_user.email
    else
      super
    end
  end
  
  def name
    if self.end_user
      self.end_user.name
    else
      nil
    end
  end
  
  def before_create #:nodoc:all
    if !verified?
      
    end
  
  end
  
  def after_create #:nodoc:all
      if !verified? && self.user_subscription.double_opt_in?
        # TODO: Send Verification Email
      elsif self.user_subscription.registration_email?
        # TODO: Send Registration Email
      end
  end
  
  def after_update #:nodoc:all
    if verified && self.user_subscription.registration_email?
      # TOTO: Send Registration Email
    end
  end
end
