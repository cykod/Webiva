
class DomainLogSource < DomainModel

  validates_presence_of :name
  validates_presence_of :source_handler

  serialize :options

  def self.chart_traffic_handler_info
    {
      :name => 'Traffic Sources',
      :icon => 'traffic_referrer.png',
      :url => { :controller => '/emarketing', :action => 'charts', :path => ['traffic'] + self.name.underscore.split('/') }
    }
  end

  def title; self.name; end
  def admin_url; nil; end

  def self.get_source(domain_log_session, session={})
    self.sources.each do |source|
      handler = self.handler_obj source[:source_handler], source[:options]
      return source if handler && handler.matches?(domain_log_session, session)
    end
    nil
  end

  def self.handler_obj(handler, options)
    return "#{handler}_options".camelize.constantize.new(options)
    rescue NameError
    nil
  end

  def matches?(session)
    self.handler_obj ? self.handler_obj.matches?(session) : false
  end

  def handler_obj
    @handler_obj ||= self.class.handler_obj self.source_handler, self.options
  end

  def configurable?
    return false unless self.handler_obj.respond_to?(:configurable?)
    self.handler_obj.configurable?
  end

  def after_save
    DataCache.expire_container self.class.name
  end

  def self.sources
    sources = DataCache.get_cached_container self.name, 'sources'
    return sources if sources
    sources = DomainLogSource.find(:all, :conditions => {:active => true}, :order => 'position').collect { |s| s.attributes.symbolize_keys }
    DataCache.put_cached_container self.name, 'sources', sources
    sources
  end

  def self.traffic_scope(from, duration, opts={})
    scope = DomainLogSession.valid_sessions.between(from, from+duration).hits_n_visits('domain_log_source_id')
    if opts[:target_id]
      scope = scope.scoped(:conditions => {:domain_log_source_id => opts[:target_id]})
    end
    scope
  end

  def self.traffic(from, duration, intervals, opts={})
    DomainLogGroup.stats(self.name, from, duration, intervals, :type => 'traffic') do |from, duration|
      DomainLogSession.update_sessions_for from, duration, 1
      self.traffic_scope from, duration, opts
    end
  end

  class AffiliateOptions < HashModel
    def matches?(domain_log_session, session)
      domain_log_session.affiliate.blank? ? false : true
    end
  end

  class EmailCampaignOptions < HashModel
    def matches?(domain_log_session, session)
      return false unless session[:from_email_campaign]
      return false unless SiteModule.module_enabled?('mailing')
      return Module.const_get('MarketCampaignQueueSession').find_by_session_id(domain_log_session.session_id) ? true : false
      rescue NameError
      return false
    end
  end

  class SocialNetworkOptions < HashModel
    attributes :sites => nil

    def matches?(domain_log_session, session)
      return false unless domain_log_session.domain_log_referrer

      self.sites.each do |site|
        return true if domain_log_session.domain_log_referrer.referrer_domain == site
      end

      false
    end

    def social_networks
      self.sites ? self.sites.join("\n") : ''
    end

    def social_networks=(networks)
      self.sites = networks.split("\n").map(&:strip).reject(&:blank?)
    end

    def sites
      @sites ? @sites : self.default_sites
    end

    def default_sites
      ['facebook.com', 'myspace.com', 'twitter.com']
    end

    def configurable?; true; end

    options_form(
                 fld(:social_networks, :text_area)
                 )
  end

  class SearchOptions < HashModel
    def matches?(domain_log_session, session)
      domain_log_session.query.blank? ? false : true
    end
  end

  class ReferrerOptions < HashModel
    def matches?(domain_log_session, session)
      domain_log_session.domain_log_referrer ? true : false
    end
  end

  class TypeInOptions < HashModel
    def matches?(domain_log_session, session); true; end
  end
end
