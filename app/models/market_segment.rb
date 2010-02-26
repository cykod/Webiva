# Copyright (C) 2009 Pascal Rettig.

class MarketSegment < DomainModel

  validates_presence_of :name, :segment_type
  
  serialize :options

  belongs_to :user_subscription
  
  has_options :segment_type,
               [ [ 'Subscription', 'subscription' ],
                 [ 'Registered Members', 'members' ] ,
                 [ 'Content Model', 'content_model'] ]
                 

  named_scope :with_segment_type, lambda { |segment_type| segment_type == 'custom' || segment_type == 'content_model' ? {:conditions => 'segment_type = "custom" || segment_type = "content_model"'} : {:conditions => ['segment_type = ?', segment_type]} }
  named_scope :for_campaign, lambda { |campaign| campaign.id ? {:conditions => ['market_campaign_id IS NULL OR market_campaign_id = ?', campaign.id]} : {:conditions => 'market_campaign_id IS NULL'} }
  named_scope :order_by_name, :order => :name

   def save_segment
    self.market_campaign_id ? 'yes' : 'no'
   end
   
   def options_model(val = nil)
    case self.segment_type
    when 'subscription': 
      SubscriptionOptions.new(val || self.options)
    when 'members': 
      MembersOptions.new(val || self.options)
    when 'content_model': 
      ContentModelOptions.new(val || self.options)
    when 'custom':
      CustomModelOptions.new(val || self.options)
    else
      DefaultsHashObject.new
    end
   
   end

   def self.create_custom(campaign,user_ids)
     self.create(:options => {  :user_ids => user_ids }, :segment_type => 'custom', :name => "#{campaign.name} Custom Segment", :market_campaign_id => campaign.id )
   end

   class CustomModelOptions < HashModel #:nodoc:all
     default_options :user_ids => []

     integer_array_options :user_ids
   end
   
   class SubscriptionOptions < HashModel #:nodoc:all
      default_options :user_subscription_id => nil
      
      validates_presence_of :user_subscription_id
   end
   
   class MembersOptions < HashModel #:nodoc:all
      default_options :filter_profiles => nil, :filter_tags => nil, :tags_type => 'any', :affected_profiles => nil, :affected_tags => :nil
      
      validates_presence_of
   end
   
   class ContentModelOptions < HashModel #:nodoc:all
    default_options :content_model_id => nil,:email_field => nil
    
    validates_presence_of :content_model_id, :email_field
   end
   
   def available_fields
    case self.segment_type
    when 'subscription':
      vars = [ 
        [ 'Email'.t,'email', [ 'email','e-mail','e mail' ] ],
        [ 'Name'.t, 'name', [ 'name', 'name'.t ] ]
      ]
    when 'members':
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
   
   def target_find(options = {})
      options = options.clone
      options.symbolize_keys!
    if self.segment_type == 'members'
      self.send('members_target_find',options)
    else
      raise 'Invalid Find'
    end
   end
   
   def content_model
    return nil unless self.options[:content_model_id]
    mdl = ContentModel.find_by_id(self.options[:content_model_id])
    mdl
   end
   
   private


   def custom_target_count(options={ })
     opts = self.options_model
     if opts.user_ids.length > 0
       EndUser.count(:conditions => { :id => opts.user_ids })
     else
       0
     end
   end

   def custom_target_list(options)
     opts = self.options_model
     if opts.user_ids.length > 0
       EndUser.find(:all,:conditions => { :id => opts.user_ids },:select => 'end_users.email,end_users.id,end_users.full_name,end_users.first_name,end_users.last_name,end_users.middle_name,end_users.client_user_id').map {  |elm| [ elm.email,elm.name ]}
     else
       []
     end
   end

   def custom_target_entries(options)
     opts = self.options_model
     if opts.user_ids.length > 0
       EndUser.find(:all,:conditions => { :id => opts.user_ids }).map {  |elm| [ elm.email,elm, elm.id ]}
     else
       []
     end
   end
   
   def subscription_target_count(options={})
    self.user_subscription.active_subscriptions.count()
   end
   
   # Return the subscription list,
   # Stop at 1000
   def subscription_target_list(options)
    self.user_subscription.active_subscriptions.find(:all,options).collect { |sub| [ sub.email, sub.name ] }
   end
   
   def subscription_target_entries(options)
    if self.user_subscription.require_registered_user?
      self.user_subscription.active_subscriptions.find(:all,options).collect { |entry| [ entry.email, entry.end_user, entry.id ] }
    else
      self.user_subscription.active_subscriptions.find(:all,options).collect { |entry| [ entry.email, entry, entry.id ] } 
    end
   end
   
   def content_model_target_count(options={})
      mdl = ContentModel.find_by_id(self.options[:content_model_id])
      mdl.content_model.count
   end
   
   def content_model_target_list(options)
      mdl = ContentModel.find_by_id(self.options[:content_model_id])
      email_field = self.options[:email_field]
      mdl.content_model.find(:all,options).collect { |sub| [ sub.send(email_field), sub.identifier_name ] }
   end
   
   def content_model_target_entries(options)
    mdl = ContentModel.find_by_id(self.options[:content_model_id])
    email_field = self.options[:email_field]
    mdl.content_model.find(:all,options).collect { |entry| [ entry.send(email_field), entry, entry.id  ] }
   end
   
   
   def member_target_affected_tag_names
      self.options ||= {}
      affected_tags =(self.options[:affected_tags].split(",") + [ 0 ]).collect { |pid| quote_value(pid) }.join(",")
      affected_tag_names = Tag.find(:all, :conditions => "tags.id IN (#{affected_tags})").collect { |tag| tag.name }
   end
   
   def members_target_count(opts={})
   opts = opts.clone

   options.symbolize_keys!
    
    conditions = options[:conditions] || '1'
    conditions = [conditions] unless conditions.is_a?(Array)

    if opts[:conditions] 
      new_conds = opts[:conditions]
      new_conds = [new_conds] unless new_conds.is_a?(Array)
    
      conditions[0] += " AND (" + new_conds[0] + ")"
      conditions += new_conds[1..-1]
  
   end
   opts[:conditions] = conditions  

   if options[:tags].is_a?(Array) && options[:tags].length > 0
    
      case options[:tags_select]
      when 'all':
        opts[:all] = options[:tags]
        EndUser.count_tagged_with(opts)
      when 'not_any':
        opts[:any] = options[:tags]
        EndUser.count_not_tagged_with(opts)
      when 'not_all':
        opts[:all] = options[:tags]
        EndUser.count_not_tagged_with(opts)
      else 
        opts[:any] = options[:tags]
        EndUser.count_tagged_with(opts)
      end
    else
      EndUser.count(:id,opts)
    end

   end
   
   def members_target_find(opts)
    opts = opts.clone
    options.symbolize_keys!
  
    conditions = options[:conditions] || '1'
    conditions = [conditions] unless conditions.is_a?(Array)

    if opts[:conditions] 
      conditions = [conditions] unless conditions.is_a?(Array)
      new_conds = opts[:conditions]
      new_conds = [new_conds] unless new_conds.is_a?(Array)
    
      conditions[0] += " AND (" + new_conds[0] + ")"
      conditions += new_conds[1..-1]
  
    end
    opts[:conditions] = conditions  

  
    if options[:tags].is_a?(Array) && options[:tags].length > 0
      case options[:tags_select]
        when 'all':
          opts[:all] = options[:tags]
          EndUser.find_tagged_with(opts)
        when 'not_any':
          opts[:any] = options[:tags]
          EndUser.find_not_tagged_with(opts)
        when 'not_all':
          opts[:all] = options[:tags]
          EndUser.find_not_tagged_with(opts)
        else 
          opts[:any] = options[:tags]
          EndUser.find_tagged_with(opts)
      end
    else
      opts[:include] = :tag_cache
      EndUser.find(:all,opts)
    end
  end   
  
   def members_target_list(options)
    members_target_find(options).collect { |usr| [ usr.email, usr.name ] }
   end
   
   def members_target_entries(options)
    members_target_find(options).collect { |usr| [ usr.email, usr, usr.id ] }
    
   end
end
