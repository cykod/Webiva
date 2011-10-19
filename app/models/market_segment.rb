# Copyright (C) 2009 Pascal Rettig.

class MarketSegment < DomainModel

  validates_presence_of :name, :segment_type
  
  serialize :options

  belongs_to :user_subscription
  
  has_options :segment_type,
               [['Subscription', 'subscription'],
                ['User List', 'user_segment'],
                ['Content Model', 'content_model'],
                ['Everyone', 'everyone']]
                 

  named_scope :with_segment_type, lambda { |segment_type| {:conditions => {:segment_type => segment_type}} }
  named_scope :for_campaign, lambda { |campaign| campaign.id ? {:conditions => ['market_campaign_id IS NULL OR market_campaign_id = ?', campaign.id]} : {:conditions => 'market_campaign_id IS NULL'} }
  named_scope :order_by_name, :order => :name

   def save_segment
    self.market_campaign_id ? 'yes' : 'no'
   end
   
   def options_model(val = nil)
    case self.segment_type
    when 'subscription'
      SubscriptionOptions.new(val || self.options)
    when 'content_model'
      ContentModelOptions.new(val || self.options)
    when 'user_segment'
      UserSegmentOptions.new(val || self.options)
    else
      DefaultsHashObject.new
    end
   end

   class SubscriptionOptions < HashModel #:nodoc:all
     default_options :user_subscription_id => nil

     validates_presence_of :user_subscription_id
   end
   
   class UserSegmentOptions < HashModel #:nodoc:all
     default_options :user_segment_id => nil

     validates_presence_of :user_segment_id
   end
   
   class ContentModelOptions < HashModel #:nodoc:all
     default_options :content_model_id => nil,:email_field => nil

     validates_presence_of :content_model_id, :email_field
   end
   
   def available_fields
    case self.segment_type
    when 'subscription'
      vars = [ 
        [ 'Email'.t,'email', [ 'email','e-mail','e mail' ] ],
        [ 'Name'.t, 'name', [ 'name', 'name'.t ] ]
      ]
    when 'user_segment', 'everyone'
      vars = [
        [ 'Email'.t,'email', [ 'email','e-mail','e mail' ] ],
        [ 'Full Name'.t, 'name', [ 'name', 'name'.t, 'full name'.t  ] ],
        [ 'First Name'.t, 'first_name', [ 'first name', 'first name'.t ] ],
        [ 'Last Name'.t, 'last_name', [ 'last name', 'last name'.t ] ],
        [ 'VIP Number'.t, 'vip_number', ['vip number','vip','vip number'.t,'vip'.t ] ],
        [ 'Gender'.t, 'gender', [ 'gender', 'gender'.t ] ],
        [ 'Introduction (Mr./Mrs.)'.t, 'introduction', [ 'introduction','introduction'.t ] ],
        [ 'Name / Friend'.t,'first_name_friend', [ 'friend' ]]
      ]
    else
      mdl = ContentModel.find_by_id(self.options[:content_model_id])
      if mdl
        vars = mdl.all_fields.collect do |fld|
          [ fld.name, fld.field, [ fld.name.downcase, fld.field.downcase ] ]
        end
      else 
        vars = []
      end
    end
    vars ||= []
    vars << [ 'Unsubscribe Link'.t,'unsubscribe', [ 'unsubscribe', 'unsubscribe_link','unsubscribe'.t] ]
    vars << [ 'View Online Link'.t,'view_online', [ 'view_online' ,'view online', 'view_online_link', 'view online link']]
    vars << [ 'Unsubscribe Url'.t,'unsubscribe_href', [ 'unsubscribe_url','unsubscribe url','unsubscribe_url' ] ]
    vars << [ 'View Online Url'.t,'view_online_href', [ 'view_online_url' ,'view online url', 'view_online_href', 'view online href']]
   end
   
   def target_count(options = {})
      options = options.clone
      options.symbolize_keys!
      self.send(self.segment_type + '_target_count',options)
   end
   
   def target_list(options = {})
      options = options.clone
      options.symbolize_keys!
      self.send(self.segment_type + '_target_list',options)
   end
   
   def target_entries(options = {})
      options = options.clone
      options.symbolize_keys!
      self.send(self.segment_type + '_target_entries',options)
   end
   
   def content_model
     return @content_model if @content_model
     return nil unless self.options[:content_model_id]
     @content_model = ContentModel.find_by_id(self.options[:content_model_id])
   end
   
   def user_segment
     return @user_segment if @user_segment
     return nil unless self.options[:user_segment_id]
     @user_segment = UserSegment.find_by_id(self.options[:user_segment_id])
   end

   def self.push_everyone_segment
     MarketSegment.first(:conditions => {:segment_type => 'everyone'}) || MarketSegment.create(:name => 'Everyone', :segment_type => 'everyone', :options => {})
   end

   def data_model_class
     case self.segment_type
     when 'subscription'
       UserSubscriptionEntry
     when 'user_segment'
       EndUser
     when 'everyone'
       EndUser
     when 'content_model'
       self.content_model.content_model
     else
       nil
     end
   end

   private

   def subscription_target_count(options={})
     return 0 unless self.user_subscription
     self.user_subscription.active_subscriptions.count()
   end
   
   # Return the subscription list,
   def subscription_target_list(options)
     return [] unless self.user_subscription
     self.user_subscription.active_subscriptions.find(:all,options).collect { |sub| [ sub.email, sub.name ] }
   end
   
   def subscription_target_entries(options)
     return [] unless self.user_subscription
     if self.user_subscription.require_registered_user?
       self.user_subscription.active_subscriptions.find(:all,options).collect { |entry| [ entry.email, entry.end_user, entry.id ] }
     else
       self.user_subscription.active_subscriptions.find(:all,options).collect { |entry| [ entry.email, entry, entry.id ] } 
     end
   end
   
   def content_model_target_count(options={})
     return 0 unless self.content_model
     self.content_model.content_model.count
   end
   
   def content_model_target_list(options)
     return [] unless self.content_model
     email_field = self.options[:email_field]
     self.content_model.content_model.find(:all,options).collect { |sub| [ sub.send(email_field), sub.identifier_name ] }
   end
   
   def content_model_target_entries(options)
     return [] unless self.content_model
     email_field = self.options[:email_field]
     self.content_model.content_model.find(:all,options).collect { |entry| [ entry.send(email_field), entry, entry.id  ] }
   end

   def user_segment_target_count(options={})
     return 0 unless self.user_segment
     self.user_segment.last_count
   end
   
   def user_segment_target_list(options)
     return [] unless self.user_segment
     self.user_segment.batch_users(options).collect { |sub| [ sub.email, sub.name ] }
   end
   
   def user_segment_target_entries(options)
     return [] unless self.user_segment
     self.user_segment.batch_users(options).collect { |entry| [ entry.email, entry, entry.id  ] }
   end

   def everyone_target_count(options={})
     EndUser.count :conditions => 'client_user_id IS NULL'
   end
   
   def everyone_target_list(options)
     scope = EndUser.scoped(:conditions => 'client_user_id IS NULL')
     scope.find(:all, options).collect { |sub| [ sub.email, sub.name ] }
   end
   
   def everyone_target_entries(options)
     scope = EndUser.scoped(:conditions => 'client_user_id IS NULL')
     scope.find(:all, options).collect { |entry| [ entry.email, entry, entry.id  ] }
   end
end
