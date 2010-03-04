# Copyright (C) 2009 Pascal Rettig.

class EmarketingController < CmsController # :nodoc: all
  include ActionView::Helpers::DateHelper

  layout 'manage'
  
  permit ['editor_visitors','editor_members','editor_mailing'], :only => :index
  permit 'editor_visitors', :except => :index

  def index
    cms_page_info('E-marketing','e_marketing')
    
    
    @subpages = [
       [ "Visitor Statistics", :editor_visitors, "emarketing_statistics.gif", { :action => 'visitors' }, 
          "View and Track Visitors to your site" ],
       [ "Real Time Statistics", :editor_visitors, "emarketing_statistics.gif", { :action => 'stats' }, 
          "View Real Time Visits to your site" ],
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
        :unique_ips => DomainLogSession.count('ip_address',:distinct => true,:conditions => conditions),
        :unique_sessions => DomainLogEntry.count('domain_log_session_id',:distinct => true,:conditions => conditions),
        :registered_users => DomainLogEntry.count('user_id',:distinct => true,:conditions => conditions + " AND user_id IS NOT NULL"),
        :anonymous_users => DomainLogSession.count('ip_address',:distinct => true,:conditions => conditions + " AND end_user_id IS NULL"),
        :total_hits => DomainLogEntry.count(:conditions => conditions)
      }
    )
    
    
    @page_stats = DomainLogEntry.find(:all,
                :group => 'node_path',
                :select => 'node_path, COUNT(*) as views',
                :order => 'views DESC')
                
                
    render :partial => 'site_statistics'
  end

  def stats
    cms_page_info([ ['E-marketing',url_for(:action => 'index') ], 'Real Time Statistics' ],'e_marketing')

    require_js 'raphael/raphael-min.js'
    require_js 'raphael/g.raphael.js'
    require_js 'raphael/g.line.js'
    require_js 'raphael/g.bar.js'
    require_js 'raphael/g.dot.js'
    require_js 'raphael/g.pie.js'
    require_js 'emarketing.js'

    @onload = 'RealTimeStatsViewer.onLoad();'
  end

  def real_time_stats_request
    now = Time.now
    from = params[:from] ? Time.at(params[:from].to_i) : nil

    conditions = from ? ['occurred_at between ? and ?', from, now] : ['occurred_at between ? and ?', 1.hour.ago, now]
    order = from ? 'occurred_at' : 'occurred_at DESC'
    @entries = DomainLogEntry.find(:all, :limit => 50, :conditions => conditions, :order => order, :include => [:domain_log_session, :user, :end_user_action])
    @remaining = from ? DomainLogEntry.count(:all, :conditions => conditions) : 0
    @remaining -= 50
    @remaining = 0 if @remaining < 0

    last_occurred_at = nil
    @entries.map! do |entry|
      last_occurred_at = entry.occurred_at.to_i

      { :id => entry.domain_log_session.id,
	:occurred => entry.occurred_at.to_i,
	:occurred_at => entry.occurred_at.strftime('%I:%M:%S %p'),
	:url => entry.url,
	:ip => entry.domain_log_session.ip_address,
	:user => entry.user? ? entry.username : nil,
	:status => entry.http_status,
	:action => entry.action
      }
    end

    @entries.reverse! if from.nil?

    @entries << {:occurred_at => nil, :remaining => @remaining} if @remaining > 0
    render :json => [now.to_i, @entries]
  end

  def real_time_charts_request
    range = (params[:range] || 5).to_i
    intervals = (params[:intervals] || 10).to_i
    update_only = (params[:update] || 0).to_i == 1

    now = Time.now
    now = now.to_i - (now.to_i % range.minutes)
    to = now
    from = now - range.minutes

    uniques = []
    hits = []
    labels = []
    (1..intervals).each do |interval|
      conditions = ['occurred_at between ? and ?', Time.at(from), Time.at(now)]
      uniques << DomainLogEntry.count('ip_address', :distinct => true, :joins => :domain_log_session, :conditions => conditions)
      hits << DomainLogEntry.count(:all, :conditions => conditions)
      labels << Time.at(now).strftime('%I:%M')
      now = from
      from -= range.minutes
      break if update_only
    end

    from = to - (range*intervals).minutes

    format = '%b %e, %Y %I:%M%P'
    data = { :range => range, :from => Time.at(from).strftime(format), :to => Time.at(to).strftime(format), :uniques => uniques, :hits => hits, :labels => labels }
    return render :json => data
  end
end
