# Copyright (C) 2009 Pascal Rettig.
#
require 'uri'



class DomainLogSession < DomainModel
  belongs_to :end_user
  has_many :domain_log_entries, :dependent => :delete_all
  belongs_to :domain_log_referrer
  belongs_to :domain_log_visitor
  belongs_to :site_version

  named_scope :between, lambda { |from, to| {:conditions => ['created_at >= ? AND created_at < ?', from, to]} }
  named_scope :visits, lambda { |group_by| group_by =~ /_id$/ ? {:select => "#{group_by} as target_id, count(*) as visits", :group => 'target_id'} : {:select => "#{group_by} as target_value, count(*) as visits", :group => 'target_value'} }
  named_scope :referrer_only, :conditions => 'domain_log_referrer_id IS NOT NULL'

  def self.start_session(user, session, request, site_node=nil)
    return unless request.session_options

    if !session[:domain_log_session] || session[:domain_log_session][:end_user_id] != user.id
      tracking = Tracking.new(request)
      session[:user_referrer] = tracking.referrer_domain if tracking.referrer_domain
      session[:domain_log_visitor] ||= {}
      ses = self.session(session[:domain_log_visitor][:id],request.session_options[:id], user, request.remote_ip, true, tracking, site_node)
      session[:domain_log_session] = { :id => ses.id, :end_user_id => user.id }
    end
  end


  def session_content
    content_node_ids = self.domain_log_entries.map(&:content_node_id).reject(&:blank?)
    content_nodes = ContentNode.batch_find(content_node_ids)
  end
  
#  validates_uniqueness_of :session_id
  def self.session(visitor_id,session_id,user,ip_address,save_entry=true,tracking=nil,site_node=nil)
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
        :affiliate_data => tracking.affiliate_data} if tracking && ses.id.nil?

      ses.attributes = {:end_user_id => user}
      ses.save if save_entry
    end 

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
  
  def calculate!
    self.update_attributes(:page_count => self.page_count(true),:last_entry_at => self.last_entry_at(true),:length => self.length(true))
  end

  def self.update_entry_stats(domain_log_session_ids)
    DomainLogSession.find(domain_log_session_ids).each do |ses|
      if ses.last_entry_at.blank? || ses.updated_at.nil? || (((ses.updated_at + 5.minutes) < Time.now) && (ses.created_at > 1.day.ago))
        ses.calculate!
      end
    end
  end

  def self.affiliate_scope(from, duration, opts={})
    scope = DomainLogSession.between(from, from+duration)
    if opts[:affiliate] && opts[:campaign]
      scope = scope.scoped(:conditions => ['affiliate = ? AND campaign = ? AND origin IS NOT NULL', opts[:affiliate], opts[:campaign]])
      scope = scope.visits('origin')
    elsif opts[:affiliate]
      scope = scope.scoped(:conditions => ['affiliate = ? AND campaign IS NOT NULL', opts[:affiliate]])
      scope = scope.visits('campaign')
    elsif opts[:campaign]
      scope = scope.scoped(:conditions => ['campaign = ? AND affiliate IS NOT NULL', opts[:campaign]])
      scope = scope.visits('affiliate')
    else
      scope = scope.scoped(:conditions => 'affiliate IS NOT NULL')
      scope = scope.visits('affiliate')
    end
    scope
  end

  def self.affiliate(from, duration, intervals, opts={})
    type = 'affiliate_traffic'
    group = 'affiliate'
    if opts[:affiliate] && opts[:campaign]
      type = 'affiliate_campaign_origin_traffic'
      group = 'origin'
    elsif opts[:affiliate]
      type = 'affiliate_campaign_traffic'
      group = 'campaign'
    elsif opts[:campaign]
      type = 'campaign_affiliate_traffic'
      group = 'affiliate'
    end

    DomainLogGroup.stats('DomainLogGroupEntry', from, duration, intervals, :type => type, :group => group, :process_stats => :process_stats, :class => DomainLogGroupEntry) do |from, duration|
      self.affiliate_scope from, duration, opts
    end
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

    def affiliate(arg='affid')
      request.parameters[arg]
    end

    def campaign(arg='c')
      request.parameters[arg]
    end

    def origin(arg='o')
      request.parameters[arg]
    end

    def affiliate_data(arg='f')
      request.parameters[arg]
    end
  end
end
