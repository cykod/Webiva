# Copyright (C) 2009 Pascal Rettig.

require 'csv'
 
class SubscriptionController < CmsController # :nodoc: all
  layout 'manage'
  permit ['editor_mailing','editor_content']

  cms_admin_paths 'e_marketing',
                  'Emarketing' => { :controller => '/emarketing' }

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
      if params[:commit]
        if @subscription.update_attributes(params[:subscription])
          flash[:notice] = (( new_sub ? 'Created' : 'Edited' ) + ' subscription "%s"') / @subscription.name
          redirect_to :action => 'index'
        end
      else
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
  
  
  end
    
