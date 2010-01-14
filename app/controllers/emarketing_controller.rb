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

    @onload = 'RealTimeStatsViewer.onLoad();'

    @chart_html = open_flash_chart_object_from_hash(url_for(:action => 'site_counts'), :div_name => 'site_counts', :width => 600, :height => 400)
  end

  def site_playback
    now = Time.now
    from = params[:from] ? Time.at(params[:from].to_i) : (now - 1.minute)

    conditions = ['occurred_at between ? and ?', from, now]
    @entries = DomainLogEntry.find(:all, :limit => 50, :conditions => conditions, :order => 'occurred_at', :include => [:domain_log_session, :user, :end_user_action])
    @remaining = DomainLogEntry.count(:all, :conditions => conditions)
    @remaining -= 50
    @remaining = 0 if @remaining < 0

    last_occurred_at = nil
    @entries.map! do |entry|
      last_occurred_at = entry.occurred_at.to_i

      { :occurred_at => entry.occurred_at.to_i,
	:url => entry.url,
	:ip => entry.domain_log_session.ip_address,
	:user => entry.username,
	:status => entry.http_status,
	:action => entry.action
      }
    end

    @entries << {:occurred_at => nil, :remaining => @remaining} if @remaining > 0
    render :json => [now.to_i, @entries]
  end

  def site_counts
    range = (params[:range] || 60).to_i
    intervals = (params[:intervals] || 10).to_i

    now = Time.now
    from = now.to_i - (now.to_i % range.minutes)

    uniques = [0]
    hits = [0]
    labels = ['']
    max_hits = 10
    (1..intervals).each do |interval|
      conditions = ['occurred_at between ? and ?', Time.at(from), Time.at(now)]
      uniques << DomainLogEntry.count('ip_address', :distinct => true, :joins => :domain_log_session, :conditions => conditions)
      page_views = DomainLogEntry.count(:all, :conditions => conditions)
      hits << page_views
      labels << Time.at(from).strftime('%I:%M')
      max_hits = page_views if page_views > max_hits
      now = from
      from -= range.minutes
    end

    from = now

    uniques << 0
    hits << 0
    labels << ''

    max_hits = (max_hits + (10 - (max_hits%10))) if (max_hits%10) != 0

    uniques_bar = OpenFlashChart::BarGlass.new
    uniques_bar.text = "Uniques"
    uniques_bar.colour = '#CC0000'
    uniques_bar.set_values uniques
    hits_bar = OpenFlashChart::BarGlass.new
    hits_bar.text = "Page Views"
    hits_bar.colour = '#0000CC'
    hits_bar.set_values hits

    x = OpenFlashChart::XAxis.new
    x.set_offset(false)
    x.set_labels(labels)
    x.rotate = 90

    x_legend = OpenFlashChart::XLegend.new("Every #{range} minutes")
    x_legend.set_style('{font-size: 12px; color: #000000}')

    y = OpenFlashChart::YAxis.new
    y.set_range(0,max_hits, max_hits/10)

    y_legend = OpenFlashChart::YLegend.new("Uniques / Page Views")
    y_legend.set_style('{font-size: 12px; color: #000000}')

    labels = OpenFlashChart::XAxisLabels.new
    labels.steps = range
    labels.visible_steps = range

    format = '%b %e, %Y %I:%M%P'
    title = OpenFlashChart::Title.new("#{Time.now.strftime(format)}   -   #{Time.at(from).strftime(format)}")
    title.set_style('{font-size: 14px; color: #000000; font-weight:bold}')

    @chart = OpenFlashChart::OpenFlashChart.new
    @chart.set_x_legend(x_legend)
    @chart.set_y_legend(y_legend)
    @chart.set_title(title)
    @chart.add_element(uniques_bar)
    @chart.add_element(hits_bar)
    @chart.x_axis = x
    @chart.y_axis = y

    render :text => @chart.render
  end
end
