# Copyright (C) 2009 Pascal Rettig.

require 'csv'
 
class SubscriptionController < CmsController
  layout 'manage'
  permit ['editor_mailing','editor_content']

  cms_admin_paths 'e_marketing',
                  'Emarketing' => { :controller => '/emarketing' },
                  'Tell-a-Friend' => {:action => 'tell_friends' }

  include ActiveTable::Controller
  active_table :subscription_table, UserSubscription,
                [ ActiveTable::IconHeader.new('',:width => 10),
                  ActiveTable::StringHeader.new('name'),
                  ActiveTable::OrderHeader.new('subscription_cnt',:label => 'Subscribers'),
                  ActiveTable::StringHeader.new('description')
                ]
                
  def display_subscription_table(display=true)
  
    @active_table_output = subscription_table_generate params, :select => 'user_subscriptions.*,COUNT(user_subscription_entries.id) as subscription_cnt',:joins => ' LEFT JOIN user_subscription_entries ON ( user_subscription_entries.user_subscription_id = user_subscriptions.id )', :group => 'user_subscriptions.id' 
  
    render :partial => 'subscription_table' if display
  end

  def index
        cms_page_info([ [ 'E-marketing', url_for(:controller => 'emarketing') ], 'User Subscriptions'],'e_marketing' )

        display_subscription_table(false)        
        @page_info,@subscriptions = UserSubscription.paginate(params[:page],:order => 'name')
            
  end

  def edit
    @subscription = UserSubscription.find_by_id(params[:path][0]) || UserSubscription.new()
    
    cms_page_info([ [ 'E-marketing', url_for(:controller => 'emarketing') ], ['User Subscriptions', url_for(:action => 'index') ],  @subscription.id ? 'Edit Subscription' : 'Create Subscription'],'e_marketing' )
        
    new_sub = @subscription.id ? false : true;
    if request.post? && params[:subscription]
      if @subscription.update_attributes(params[:subscription])
        flash[:notice] = (( new_sub ? 'Created' : 'Edited' ) + ' subscription "%s"') / @subscription.name
        redirect_to :action => 'index'
      end
    end 
  end
  
   active_table :entry_table, UserSubscriptionEntry,
                [ ActiveTable::IconHeader.new('',:width => 10),
                  ActiveTable::StringHeader.new('end_users.email',:label => 'Email'),
                  ActiveTable::DateRangeHeader.new('subscribed_at',:label => 'Subscribed At'),
                  ActiveTable::OptionHeader.new('subscription_type', :options => :subscription_type,:label => 'Type')
                ]
  protected
  
  def subscription_type
    UserSubscriptionEntry.subscription_type_select_options
  end
          
  public
          
  def display_entry_table(display=true)
    @subscription = UserSubscription.find(params[:path][0])
    
    
     active_table_action('entry') do |act,entry_ids|
      case act
        when 'unsubscribe':
          UserSubscriptionEntry.destroy(entry_ids)
        end
     end
  
    @active_table_output = entry_table_generate params, :conditions => ['user_subscription_id = ?',@subscription.id ], :include => :end_user
  
    render :partial => 'entry_table' if display
  end  
  
  def view
    cms_page_info([ [ 'E-marketing', url_for(:controller => 'emarketing') ],['User Subscriptions', url_for(:action => 'index') ], 'View Subscription'],'e_marketing' )
    
    display_entry_table(false)
  end
  
  def delete
    @subscription = UserSubscription.find(params[:path][0])
    
    if request.post?
      @subscription.destroy
    end
    render :nothing => true
  end
  
  
  
  def download
    @subscription = UserSubscription.find(params[:path][0])

    @emails = @subscription.active_subscriptions.find(:all,:include => :end_user).collect(&:email)
    
    output = ''
    CSV::Writer.generate(output) do |csv|
      csv << [ 'Email Address' ]
      @emails.each { |email|  csv << [ email ] }
    end
    
    
    send_data(output,
      :stream => true,
      :type => "text/csv",
	    :disposition => 'attachment',
	    :filename => sprintf("%s_%d.%s",@subscription.name.humanize.gsub(" ","_").gsub("[^a-zA-Z0-9_\-]+",''),Time.now.strftime("%Y_%m_%d"),'csv')
	    )
    
  
  end
  
  active_table :email_friend_table, EmailFriend,
                [ ActiveTable::IconHeader.new('',:width => 10),
                  ActiveTable::StringHeader.new('from_name'),
                  ActiveTable::StringHeader.new('end_users.email', :label => 'User'),
                  ActiveTable::StringHeader.new('to_email'),
                  ActiveTable::StringHeader.new('site_url'),
                  ActiveTable::DateRangeHeader.new('sent_at')
                ]
  
  def tell_friends
    cms_page_path [ 'Emarketing'],'Tell-a-Friend'
    
    display_email_friend_table(false)
  end
  
  def display_email_friend_table(display = true)
    
    @tbl = email_friend_table_generate params, :order => 'sent_at DESC', :include => :end_user
    
    render :partial => 'email_friend_table' if display
  
  end
  
  def email_friend
    @entry = EmailFriend.find_by_id(params[:path][0])
    
    render :partial => 'email_friend'
  end
  
  active_table :email_friend_group_table, EmailFriend,
                [ ActiveTable::StringHeader.new('site_url'),
                  ActiveTable::NumberHeader.new('count'),
                  ActiveTable::DateRangeHeader.new('sent_at')
                ]  
    
  def tell_friends_group
    cms_page_path [ 'Emarketing','Tell-a-Friend'],'Statistics'

    display_email_friend_group_table(false) 
      
  end
  
 def tell_friends_download_all
   @tbl = email_friend_table_generate params, :order => 'sent_at DESC', :include => :end_user, :all => 1
    
    output = ''
    
    CSV::Writer.generate(output) do |csv|
      csv << [ 'From Name', 'From Email', 'To Email', 'Site Url', 'Sent At' ]
      @tbl[1].each { |t|  csv << [ t.from_name,t.end_user ? t.end_user.email : '-', t.to_email, t.site_url,t.sent_at.strftime(DEFAULT_DATETIME_FORMAT.t) ] } 
    end
    
    
    send_data(output,
      :stream => true,
      :type => "text/csv",
	    :disposition => 'attachment',
	    :filename => "send_to_friend_statistics.csv"
	    )
  
  end  
  
  def download_group_data
    @tbl = email_friend_group_table_generate params,:order => 'sent_at DESC', :group => 'site_url',:select => 'COUNT(*) as count, site_url,MAX(sent_at) as sent_max, MIN(sent_at) as sent_min', :count_by => 'site_url', :all => 1
    
    output = ''
    CSV::Writer.generate(output) do |csv|
      csv << [ 'Site Url', 'Count','Sent Between' ]
      @tbl[1].each { |t|  csv << [ t.count,t.site_url, "#{t.sent_min ? Time.parse(t.sent_min).strftime(DEFAULT_DATE_FORMAT.t) : '-'} - #{t.sent_max ? Time.parse(t.sent_max).strftime(DEFAULT_DATE_FORMAT.t) : '-'}" ] }
    end
    
    
    send_data(output,
      :stream => true,
      :type => "text/csv",
	    :disposition => 'attachment',
	    :filename => "send_to_friend_statistics.csv"
	    )
  end
    
  def display_email_friend_group_table(display=true)
  
    @tbl =email_friend_group_table_generate params, :order => 'sent_at DESC', :group => 'site_url',:select => 'COUNT(*) as count, site_url,MAX(sent_at) as sent_max, MIN(sent_at) as sent_min', :count_by => 'site_url'
    
    render :partial => 'email_friend_group_table' if display
  end
  
  def view_email
    @email = EmailFriend.find_by_id(params[:path][0])
    render :partial => 'email_friend'
  end
  
end
