# Copyright (C) 2009 Pascal Rettig.

class UserSubscription < DomainModel
  validates_presence_of :name
  
  has_one :market_segment, :dependent => :destroy

  has_many :user_subscription_entries, :dependent => :delete_all, :include => :end_user
  
  has_many :active_subscriptions, :class_name => 'UserSubscriptionEntry', :conditions => 'verified = 1 AND subscribed=1'
  has_many :unsubscribed_entries, :class_name => 'UserSubscriptionEntry', :conditions => 'verified = 1 AND subscribed=0'
  
  def after_create #:nodoc:all
    MarketSegment.create(:user_subscription_id => self.id, :name => 'Subscribers to '.t + self.name ,:segment_type => 'subscription',
                         :options => { 'user_subscription_id' =>  self.id },
                         :description => 'Sends an Campaign to all users who are subscribed to this subscription'.t )
  end
  
  def after_update #:nodoc:all
    if self.market_segment
      self.market_segment.name = 'Subscribers to '.t + self.name
      self.market_segment.save
    end
  end
  
  # Subscribe a user via a admin subscription
  def admin_subscribe_user(user,options={})
    self.user_subscription_entries.find_by_end_user_id(user.id) ||
    self.user_subscription_entries.create(
              :end_user_id => user.id,
              :subscription_type => 'admin',
              :subscribed_at => Time.now,
              :verified => self.double_opt_in? ? false : true)
  end

  # Subscribe a user via a stie subscription
  def subscribe_user(user,options={})
    self.user_subscription_entries.find_by_end_user_id(user.id) ||
    self.user_subscription_entries.create(
              :end_user_id => user.id,
              :subscription_type => 'site',
              :subscribed_at => Time.now,
              :subscribed_ip => options[:ip_address],
              :verified => self.double_opt_in? ? false : true)
  end
  
  
  
end
