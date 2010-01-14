# Copyright (C) 2009 Pascal Rettig.

class EmarketingController < CmsController # :nodoc: all
  layout 'manage'
  
  permit ['editor_visitors','editor_members','editor_mailing'], :only => :index
  permit 'editor_visitors', :except => :index

  def index
    cms_page_info('E-marketing','e_marketing')
    
    
    @subpages = [
       [ "Visitor Statistics", :editor_visitors, "emarketing_statistics.gif", { :action => 'visitors' }, 
          "View and Track Visitors to your site" ],
       [ "Tell-a-Friend Emails", :editor_content, "emarketing_members.gif",  { :controller => "/subscription",:action => "tell_friends" },
          "See emails sent with Tell-a-friend" ],
       [ "Subscriptions", :editor_mailing,"emarketing_subscriptions.gif", { :controller => '/subscription' },
          "Edit Newsletters and Mailing Lists Subscriptions" ],
       [ "Email Templates", :editor_mailing,"emarketing_templates.gif", { :controller => '/mail_manager', :action => 'templates' },
          "Edit Mail Templates" ]
          
        ]
    
  end
  
 include ActiveTable::Controller   
  active_table :visitor_table,
                DomainLogSession,
                [ ActiveTable::StaticHeader.new('user', :label => 'Who'),
                  ActiveTable::DateRangeHeader.new('created_at', :label => 'When'),
                  ActiveTable::StaticHeader.new('page_count', :label => 'Pages'),
                  ActiveTable::StaticHeader.new('time_on_site', :label => 'Stayed')
                ]
  
  def visitor_table_output(opts)
     option_hash = 
        { :order => 'created_at DESC'
        }
     if(session[:visitor_exclude_anon].to_i == 1) 
      option_hash[:conditions] =  'end_user_id is not null'
     end


     @active_table_output = visitor_table_generate opts, option_hash
  end  
  
  def visitor_update
    visitor_table_output(params)
    
    render :partial => 'visitor_table'
  end
  
  def visitors
    cms_page_info([ ['E-marketing',url_for(:action => 'index') ], 'Visitors' ],'e_marketing')
    visitor_table_output params
    
    google = Configuration.google_analytics
    @options = DefaultsHashObject.new({
                      :google_analytics => google[:enabled] ? 'enabled' : 'disabled',
                      :analytics_code => google[:code],
                })
  end
  
  def options_update
    options = params[:options]
    
    google = Configuration.retrieve('google_analytics',{})
    google.options[:enabled] = options[:google_analytics] == 'enabled' ? 'enabled' : 'disabled'
    google.options[:code] = options[:analytics_code]
    google.save
    
    render :nothing => true
  end
  
  def visitor_detail
    session_id = params[:path][0]
    
    @entry = DomainLogEntry.find_by_domain_log_session_id(session_id,:order => 'occurred_at DESC')
    if @entry && @entry.user
      @user = @entry.user
    end
    
    @entry_info,@entries = DomainLogEntry.find_anonymous_session(session_id)
    
    render :partial => 'visitor_detail'
  end
  
  def site_statistics
    conditions = '1'
  
    @stats = DefaultsHashObject.new(
      { 
        :unique_ips => DomainLogEntry.count('ip_address',:distinct => true,:conditions => conditions),
        :unique_sessions => DomainLogEntry.count('domain_log_session_id',:distinct => true,:conditions => conditions),
        :registered_users => DomainLogEntry.count('user_id',:distinct => true,:conditions => conditions + " AND user_id IS NOT NULL"),
        :anonymous_users => DomainLogEntry.count('ip_address',:distinct => true,:conditions => conditions + " AND user_id IS NULL"),
        :total_hits => DomainLogEntry.count(:conditions => conditions)
      }
    )
    
    
    @page_stats = DomainLogEntry.find(:all,
                :group => 'node_path',
                :select => 'node_path, COUNT(*) as views',
                :order => 'views DESC')
                
                
    render :partial => 'site_statistics'
  end
  
end
