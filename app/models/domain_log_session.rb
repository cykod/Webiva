# Copyright (C) 2009 Pascal Rettig.
#
require 'uri'



class DomainLogSession < DomainModel
  belongs_to :end_user
  has_many :domain_log_entries, :dependent => :delete_all
  belongs_to :domain_log_referrer
  belongs_to :domain_log_visitor
  belongs_to :site_version
  belongs_to :domain_log_source

  named_scope :between, lambda { |from, to| {:conditions => ['domain_log_sessions.created_at >= ? AND domain_log_sessions.created_at < ?', from, to]} }
  named_scope :visits, lambda { |group_by| group_by =~ /_id$/ ? {:select => "#{group_by} as target_id, count(*) as visits", :group => 'target_id'} : {:select => "#{group_by} as target_value, count(*) as visits", :group => 'target_value'} }
  named_scope :hits_n_visits, lambda { |group_by| self.hits_n_visits_options group_by }
  named_scope :hits_n_visits_n_uniques, lambda { |group_by| self.hits_n_visits_options group_by, true }
  named_scope :referrer_only, :conditions => 'domain_log_referrer_id IS NOT NULL'
  named_scope :valid_sessions, :conditions => '`ignore` = 0 AND domain_log_source_id IS NOT NULL'


  def self.hits_n_visits_options(group_by=nil, uniques=false)
    select = "count(*) as visits, sum(page_count) as hits, sum(session_value) as total_value, SUM(IF(domain_log_sessions.user_level=3,1, 0)) AS subscribers, SUM(IF(domain_log_sessions.user_level=4,1, 0)) AS leads, SUM(IF(domain_log_sessions.user_level=5,1, 0)) AS conversions"

    select += ", count(DISTINCT ip_address) as stat1" if uniques

    return {:select => select} unless group_by

    group_by = group_by.to_s
    if group_by =~ /_id$/
      select += ", #{group_by} as target_id"
      return {:select => select, :group => 'target_id'}
    end

    select += ", #{group_by} as target_value"
    {:select => select, :group => 'target_value'}
  end

  def self.start_session(user, session, request, site_node=nil, ignore=true)
    return unless request.session_options

    if !session[:domain_log_session] || session[:domain_log_session][:end_user_id] != user.id
      tracking = Tracking.new(request)
      user.referrer = tracking.referrer_domain if tracking.referrer_domain
      session[:domain_log_visitor] ||= {}
      ses = self.session(session[:domain_log_visitor][:id],request.session_options[:id], user, request.remote_ip, true, tracking, site_node, ignore, session)
      session[:domain_log_session] = { :id => ses.id, :end_user_id => user.id }
    end
  end


  def session_content
    content_node_ids = self.domain_log_entries.map(&:content_node_id).reject(&:blank?)
    content_nodes = ContentNode.batch_find(content_node_ids)
  end
  
#  validates_uniqueness_of :session_id
  def self.session(visitor_id,session_id,user,ip_address,save_entry=true,tracking=nil,site_node=nil,ignore=true,full_session=nil)
    user = user.id if user.is_a?(EndUser)
    returning (self.find_by_session_id(session_id) || self.new(:session_id => session_id, :ip_address => ip_address)) do |ses|

      if(tracking && tracking.referrer_domain)
        referrer_id =  DomainLogReferrer.fetch_referrer(tracking.referrer_domain,tracking.referrer_path).id
      else
        referrer_id = nil
      end

      ses.attributes = {
        :domain_log_visitor_id => visitor_id,
        :affiliate => tracking.affiliate,
        :campaign => tracking.campaign,
        :origin => tracking.origin,
        :domain_log_referrer_id => referrer_id,
        :query => tracking.search,
        :domain_id => DomainModel.active_domain_id,
        :site_version_id => site_node ? site_node.site_version_id : nil,
        :ignore => ignore,
        :affiliate_data => tracking.affiliate_data} if tracking && ses.id.nil?

      ses.attributes = {:end_user_id => user}

      unless ignore
        source = DomainLogSource.get_source ses, full_session if full_session
        ses.domain_log_source_id = source[:id] if source
      end

      ses.save if save_entry
    end 

  end

  def before_save
    self.ignore ||= true if self.end_user_id && self.end_user && self.end_user.client_user?
  end

  def username
    self.end_user_id ? self.end_user.name : 'Anonymous'.t
  end

  def page_count(force = false)
    atr =  self.read_attribute(:page_count)
    if atr.blank? || force
      self.domain_log_entries.count
    else
      atr
    end
  end

  def last_entry_at(force = false)
    atr = self.read_attribute(:last_entry_at)
    if atr.blank? || force
      self.domain_log_entries.maximum(:occurred_at)
    else  
      atr
    end
  end
  
  def length(force = false)
    atr = self.read_attribute(:length)
    if atr.blank? || force
      last = self.last_entry_at
      last ? (last - self.created_at).to_i : 0
    else
      atr
    end
  end
  
  def session_value(force = false)
    atr =  self.read_attribute(:session_value)
    if atr.blank? || force
      self.domain_log_entries.sum(:value)
    else
      atr
    end
  end

  def calculate!
    self.update_attributes(:page_count => self.page_count(true), :last_entry_at => self.last_entry_at(true), :length => self.length(true), :session_value => self.session_value(true), :updated_at => Time.now)
  end

  def self.update_stats(domain_log_session_id, page_count, last_entry_at, session_value)
    session_value ||= 0

    session_value = DomainModel.connection.quote session_value
    domain_log_session_id = DomainModel.connection.quote domain_log_session_id
    page_count = DomainModel.connection.quote page_count
    last_entry_at = DomainModel.connection.quote last_entry_at
    updated_at = DomainModel.connection.quote Time.now

    DomainLogSession.connection.execute "UPDATE `domain_log_sessions` SET page_count = #{page_count}, last_entry_at = #{last_entry_at}, length = UNIX_TIMESTAMP(#{last_entry_at}) - UNIX_TIMESTAMP(created_at), updated_at = #{updated_at}, session_value = #{session_value} WHERE id = #{domain_log_session_id}"
  end

  def self.update_sessions_for(from, duration, intervals)
    # Find all sessions that need to be updated
    ids = DomainLogSession.between(from, from+duration*intervals).find(:all, :select => 'id', :conditions => ['last_entry_at IS NULL || updated_at IS NULL || (updated_at < ? && created_at > ?)', 5.minutes.ago, 1.day.ago]).collect(&:id)

    unless ids.empty?

      # calculate page_count and last_entry_at for sessions
      DomainLogEntry.find(:all, :select => 'domain_log_session_id, count(*) as page_count, max(occurred_at) as last_entry_at, SUM(`value`) as session_value', :group => 'domain_log_session_id', :conditions => {'domain_log_session_id' => ids}).each do |entry|

        # update the session
        DomainLogSession.update_stats entry.domain_log_session_id, entry.page_count, entry.last_entry_at, entry.session_value
      end
    end
  end

  def self.update_sessions(sessions)
    sessions.each do |session|
      session.calculate! if session.last_entry_at.nil? || session.updated_at.nil? || (session.updated_at < 5.minutes.ago && session.created_at > 1.day.ago)
    end
  end

  def self.affiliate_scope(from, duration, opts={})
    scope = DomainLogSession.valid_sessions.between(from, from+duration)
    scope = scope.scoped(:conditions => {:affiliate => opts[:affiliate]}) if opts[:affiliate]
    scope = scope.scoped(:conditions => {:campaign => opts[:campaign]}) if opts[:campaign]
    scope = scope.scoped(:conditions => {:origin => opts[:origin]}) if opts[:origin]

    case opts[:display]
    when 'origin'
      scope = scope.hits_n_visits_n_uniques('origin').scoped(:conditions => 'origin IS NOT NULL')
    when 'campaign'
      scope = scope.hits_n_visits_n_uniques('campaign').scoped(:conditions => 'campaign IS NOT NULL')
    else
      scope = scope.hits_n_visits_n_uniques('affiliate').scoped(:conditions => 'affiliate IS NOT NULL')
    end

    scope
  end

  def self.affiliate(from, duration, intervals, opts={})
    group = opts[:display] || 'affiliate'
    type = "a:#{opts[:affiliate]}:c:#{opts[:campaign]}:o:#{opts[:origin]}:#{group}_traffic"

    DomainLogSession.update_sessions_for from, duration, intervals

    DomainLogGroup.stats(self.name, from, duration, intervals, :type => type, :group => group, :has_target_entry => true) do |from, duration|
      self.affiliate_scope from, duration, opts
    end
  end

  def self.get_affiliates
    data = DataCache.get_container 'Affiliates', nil
    return data['affiliates'], data['campaigns'], data['origins'] if data
    affiliates = DomainLogSession.find(:all, :select => 'DISTINCT affiliate', :conditions => ['affiliate IS NOT NULL && created_at > ?', 2.months.ago]).collect(&:affiliate)
    campaigns = DomainLogSession.find(:all, :select => 'DISTINCT campaign', :conditions => ['campaign IS NOT NULL && created_at > ?', 2.months.ago]).collect(&:campaign)
    origins = DomainLogSession.find(:all, :select => 'DISTINCT origin', :conditions => ['origin IS NOT NULL && created_at > ?', 2.months.ago]).collect(&:origin)
    DataCache.put_container 'Affiliates', nil, {'affiliates' => affiliates, 'campaigns' => campaigns, 'origins' => origins}, 10.minutes
    return affiliates, campaigns, origins
  end

  def self.log_source(cookies, session)
    return unless session[:domain_log_session] && session[:domain_log_session][:id]

    ses = DomainLogSession.find_by_id session[:domain_log_session][:id]
    return unless ses

    source = DomainLogSource.get_source ses, session
    ses.update_attributes :ignore => false, :domain_log_source_id => source[:id] if source
  end

  def self.cron_update_sessions(opts={})
    return unless opts[:hour] == 4
    self.update_sessions_for 1.day.ago, 1.day, 1
  end

  class Tracking
    attr_accessor :request

    def initialize(request)
      @request = request
      begin
        @referrer = URI::parse(request.referrer) unless request.referrer.blank?
      rescue URI::InvalidURIError
        @referrer = nil
      end
    end
    
    def referrer_domain
      return nil unless @referrer
      @referrer_domain ||= @referrer.host.to_s.gsub(/^www\./,'')
      domain_exp = Regexp.new('(^|\.)' + Regexp.escape(DomainModel.active_domain_name) + '$')
      return @referrer_domain unless domain_exp.match(@referrer_domain)
      nil
    end

    def referrer_path
      return nil unless self.referrer_domain
      @referrer_path ||= @referrer.path
    end

    def query
      return nil unless self.referrer_domain
      @query ||= CGI::parse(@referrer.query ? @referrer.query : @referrer.fragment.to_s)
    end

    def search
      return nil unless query
      terms = case self.referrer_domain
      when 'www.google.com', 'google.com', 'www.bing.com', 'bing.com': query['q']
      when 'www.yahoo.com', 'yahoo.com', 'search.yahoo.com': query['p']
      else nil
      end
      terms ? terms[0] : nil
    end

    def affiliate
      request.parameters['affid'] || request.parameters['utm_source']
    end

    def campaign
      request.parameters['c'] || request.parameters['utm_campaign']
    end

    def origin
      request.parameters['o'] || request.parameters['utm_medium']
    end

    def affiliate_data
      request.parameters['f'] || request.parameters['utm_content']
    end
  end
end
