# Copyright (C) 2009 Pascal Rettig.



class DomainLogSession < DomainModel
  belongs_to :end_user
  has_many :domain_log_entries

  def self.start_session(user, session, request)
    return unless request.session_options

    if !session[:domain_log_session] || session[:domain_log_session][:end_user_id] != user.id
      ses = self.session(request.session_options[:id], user, request.remote_ip, true, Tracking.new(request))
      session[:domain_log_session] = { :id => ses.id, :end_user_id => user.id }
    end
  end
  
#  validates_uniqueness_of :session_id
  def self.session(session_id,user,ip_address,save_entry=true,tracking=nil)
    user = user.id if user.is_a?(EndUser)
    returning (self.find_by_session_id(session_id) || self.new(:session_id => session_id, :ip_address => ip_address)) do |ses|

      ses.attributes = {:referrer_domain => tracking.referrer_domain,
	                :referrer_path => tracking.referrer_path,
	                :affiliate => tracking.affiliate,
	                :campaign => tracking.campaign,
	                :origin => tracking.origin,
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

  class Tracking
    attr_accessor :request

    def initialize(request)
      @request = request
    end
    
    def referrer_domain
      return nil unless request.referrer
      @referrer_domain ||= request.referrer.sub(/https?:\/\//, '').sub(/\/.*/, '')
      domain_exp = Regexp.new('(^|\.)' + Regexp.escape(DomainModel.active_domain_name) + '$')
      return @referrer_domain unless domain_exp.match(@referrer_domain)
      nil
    end

    def referrer_path
      return nil unless self.referrer_domain
      @referrer_path ||= request.referrer.sub(/https?:\/\/.*?\//, '/').sub(/\?.*/, '').sub(/#.*/, '')
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
