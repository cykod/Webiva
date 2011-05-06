# Copyright (C) 2009 Pascal Rettig.

class EmarketingController < CmsController # :nodoc: all
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper

  layout 'manage'

  cms_admin_paths 'marketing',
    'Marketing' => { :action => 'index' }
  
  permit 'editor_visitors'

  def index
    cms_page_path [],'Marketing'

    @subpages = [
       [ "Visitor Statistics", :editor_visitors, "traffic_visitors.png", { :action => 'visitors' }, 
          "View and Track Visitors to your site" ],
       [ "Real Time Statistics", :editor_visitors, "traffic_realtime.png", { :action => 'stats' }, 
          "View Real Time Visits to your site" ]
    ]

    get_handler_info(:chart, :traffic).each do |handler|
      @subpages << [handler[:name], :editor_visitors, handler[:icon] || 'traffic_page.png', handler[:url], (handler[:description] || handler[:name]) ]
    end

    require_js 'protovis/protovis-r3.2'
    require_js 'protovis/protovis-d3.2'
    require_js 'tipsy/jquery.tipsy'
    require_js 'protovis/tipsy'
    require_js 'charts/sources'
    require_css 'tipsy/tipsy.css'

    @site_traffic = {
      :today => DomainLogEntry.traffic(Time.now.at_midnight, 1.day, 1),
      :yesterday => DomainLogEntry.traffic(1.day.ago.at_midnight, 1.day, 1),
      :this_week => DomainLogEntry.traffic(Time.now.at_beginning_of_week, 1.week, 1)
    }

    referrer_sources(false)

    @subpages << ['Affiliate Traffic', :editor_visitors, 'traffic_visitors.png', {:action => 'affiliates'}, 'View Affiliate Traffic']

    @subpages << ['Experiments', :editor_visitors, 'traffic_visitors.png', {:controller => '/experiment', :action => 'index'}, 'View Experiments Results']
  end


  def referrer_sources(display=true)
    interval = 3

    @date = params[:date] ? Time.parse(params[:date]) : Time.now - (interval-1).days
    case params[:direction]
    when 'prev'
      @date -= 1.day
    when 'next'
      @date += 1.day
    end

    @groups = DomainLogSource.traffic(@date.at_midnight, 1.day, interval)
    @sources = DomainLogSource.sources.reverse

    @traffic = @groups.collect do |group|
      hits = 0
      visits = 0
      subscribers = 0
      leads = 0
      conversions = 0
      total_value = 0

      stats = group.domain_log_stats.index_by(&:target_id)

      group.domain_log_stats.each do |stat|
        hits += stat.hits.to_i
        visits += stat.visits.to_i
        subscribers += stat.subscribers.to_i
        leads += stat.leads.to_i
        conversions += stat.conversions.to_i
        total_value += stat.total_value.to_f
      end

      { :started_at => group.started_at,
        :ended_at => group.ended_at,
        :duration => group.duration,
        :total_value => total_value,
        :hits => hits,
        :visits => visits,
        :user_levels => [(visits - (subscribers + leads + conversions)), conversions, leads, subscribers],
        :sources => @sources.collect { |source| stats[source[:id]] ? stats[source[:id]].visits : 0 }
      }
    end

    if display
      render :json => {
        :date => @date.localize('%F'),
        :user_levels => @traffic.collect{|t| t[:user_levels][1..-1]},
        :sources => @traffic.collect{|t| t[:sources]},
        :total_values => @traffic.collect{|t| t[:total_value].to_f > 0.0 ? number_to_currency(t[:total_value]) : ''},
        :days => @traffic.collect{|t| t[:started_at].localize('%A'.t)},
        :dates => @traffic.collect{|t| t[:started_at].localize(Configuration.date_format)}
      }
    end
  end

 include ActiveTable::Controller   
  active_table :visitor_table,
                DomainLogVisitor,
                [ ActiveTable::StaticHeader.new('user', :label => 'Who'),
                  ActiveTable::DateRangeHeader.new('created_at', :label => 'When'),
                  ActiveTable::StaticHeader.new('page_count', :label => 'Pages'),
                  ActiveTable::StaticHeader.new('time_on_site', :label => 'Stayed')
                ]
  
  def visitor_table_output(opts)
     option_hash = 
        { :order => 'updated_at DESC'
        }
     @active_table_output = visitor_table_generate opts, option_hash
  end  
  
  def visitor_update
    visitor_table_output(params)
    
    render :partial => 'visitor_table'
  end
  
  def visitors
    cms_page_path ['Marketing'], 'Visitors'
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
    visitor_id = params[:path][0]
    
    @entry = DomainLogVisitor.find_by_id(visitor_id)
    if @entry && @entry.end_user
      @user = @entry.end_user
    end
    
    @sessions = @entry.session_details
    
    render :partial => 'visitor_detail'
  end
  
  def stats
    cms_page_path ['Marketing'], 'Real Time Statistics'
    require_js 'emarketing.js'
  end

  def charts
    @stat_type = params[:path][0]
    @handler, @format = params[:path][1..-1].join('/').split('.')
    if @handler =~ /\/(\d+)$/
      @target_id = $1.to_i
      @handler.sub!("/#{@target_id}", '')
    end
    @type_id = params[:type_id] ? params[:type_id].to_i : nil
    @type_id = nil if @type_id == 0

    @chart_info = get_handler_info(:chart, @stat_type, @handler)

    raise 'No chart found' unless @chart_info

    @when = params[:when] || 'today'
    @all_fields = params[:all]

    @from = Time.now.at_midnight
    @duration = 1.day
    @interval = 1

    @when_options = [['Today', 'today'], ['Yesterday', 'yesterday'], ['This Week', 'week'], ['Last Week', 'last_week'], ['This Month', 'month'], ['Last Month', 'last_month']]

    case @when
    when 'today'
      @from = Time.now.at_midnight
      @duration = 1.day
    when 'yesterday'
      @from = Time.now.at_midnight.yesterday
      @duration = 1.day
    when 'week'
      @from = Time.now.at_beginning_of_week
      @duration = 1.week
    when 'last_week'
      @from = Time.now.at_beginning_of_week - 1.week
      @duration = 1.week
    when 'month'
      @from = Time.now.at_beginning_of_month
      @duration = 1.month
    when 'last_month'
      @from = Time.now.at_beginning_of_month - 1.month
      @duration = 1.month
    end

    groups = @chart_info[:class].send(@stat_type, @from, @duration, @interval, :target_id => @target_id, :type_id => @type_id)
    @group = groups[0]
    @stats = @target_id ? @group.target_stats : @group.domain_log_stats
    @stats.delete_if { |stat| stat.target.nil? }
    @title = @chart_info[:title] || :title

    if @format == 'json'
      data = {:from => @from, :duration => @duration, :stat_type => @stat_type, :when => @when, :target_id => @target_id, :type_id => @type_id}
      if @all_fields
        data[:columns] = ['Visitors', 'Hits', 'Subscribers', 'Leads', 'Conversions']
        data[:data] = @stats.collect { |stat| [stat.visits, stat.hits, stat.subscribers, stat.leads, stat.conversions] }
      else
        data[:columns] = ['Visitors', 'Hits']
        data[:data] = @stats.collect { |stat| [stat.visits, stat.hits] }
      end
      return render :json => data
    elsif @format == 'csv'
      report = StringIO.new
      csv_data = FasterCSV.generate do |writter|
        writter << ['Title', 'Visitors', 'Hits', 'Subscribers', 'Leads', 'Conversions']
        @stats.each do |stat|
          writter << [stat.target.send(@title), stat.visits, stat.hits, stat.subscribers, stat.leads, stat.conversions]
        end
      end
      return send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=stats.csv"
    end

    if @chart_info[:type_options]
      @type_options = @chart_info[:type_options].is_a?(Symbol) ? @chart_info[:class].send(@chart_info[:type_options]) : @chart_info[:type_options]
    end

    cms_page_path ['Marketing'], @chart_info[:name]

    require_js 'protovis/protovis-r3.2.js'
    require_js 'tipsy/jquery.tipsy.js'
    require_js 'protovis/tipsy.js'
    require_css 'tipsy/tipsy.css'
    require_js 'charts.js'
  end

  def affiliates
    @affiliate = params[:affiliate]
    @campaign = params[:campaign]
    @origin = params[:origin]
    @display = params[:display]
    @affiliate = nil if @affiliate.blank?
    @campaign = nil if @campaign.blank?
    @origin = nil if @origin.blank?
    @display = nil if @display.blank?

    @stat_type = 'affiliate'

    @when = params[:when] || 'today'
    @all_fields = params[:all]

    @from = Time.now.at_midnight
    @duration = 1.day
    @interval = 1

    @when_options = [['Today', 'today'], ['Yesterday', 'yesterday'], ['This Week', 'week'], ['Last Week', 'last_week'], ['This Month', 'month'], ['Last Month', 'last_month']]

    case @when
    when 'today'
      @from = Time.now.at_midnight
      @duration = 1.day
    when 'yesterday'
      @from = Time.now.at_midnight.yesterday
      @duration = 1.day
    when 'week'
      @from = Time.now.at_beginning_of_week
      @duration = 1.week
    when 'last_week'
      @from = Time.now.at_beginning_of_week - 1.week
      @duration = 1.week
    when 'month'
      @from = Time.now.at_beginning_of_month
      @duration = 1.month
    when 'last_month'
      @from = Time.now.at_beginning_of_month - 1.month
      @duration = 1.month
    end

    groups = DomainLogSession.affiliate @from, @duration, @interval, :affiliate => @affiliate, :campaign => @campaign, :origin => @origin, :display => @display
    @group = groups[0]
    @stats = @group.domain_log_stats
    @stats.delete_if { |stat| stat.target.nil? }

    @displays = [['Affiliate', 'affiliate'], ['Campaign', 'campaign'], ['Origin', 'origin']]
    @affiliates, @campaigns, @origins = DomainLogSession.get_affiliates

    cms_page_path ['Marketing'], 'Affiliates'

    require_js 'protovis/protovis-r3.2.js'
    require_js 'tipsy/jquery.tipsy.js'
    require_js 'protovis/tipsy.js'
    require_css 'tipsy/tipsy.css'
    require_js 'charts.js'
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

      { :id => entry.domain_log_session.domain_log_visitor_id || '#',
	:occurred => entry.occurred_at.to_i,
	:occurred_at => entry.occurred_at.localize('%I:%M:%S %p'),
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
    update_only = params[:update]
    site_node_id = params[:site_node_id]

    now = Time.now
    now = now.to_i - (now.to_i % range.minutes)
    from = now - (range*intervals).minutes

    groups = []
    if site_node_id
      site_node = SiteNode.find_by_id site_node_id
      groups = site_node.traffic(Time.at(from), range.minutes, intervals) if site_node
    else
      groups = DomainLogEntry.traffic Time.at(from), range.minutes, intervals
    end

    return render :json => DomainLogGroup.traffic_chart_data(groups, :desc => true, :update_only => update_only).merge(:range => range)
  end
end
