
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

  def self.get_source(session)
    self.sources.each do |source|
      return source if source.matches?(session)
    end
    nil
  end

  def matches?(session)
    self.handler_obj ? self.handler_obj.matches?(session) : false
  end

  def handler_obj
    return @handler_obj ||= "#{self.source_handler}_options".camelize.constantize.new(self.options)
    rescue NameError
    nil
  end

  def configurable?
    return false unless self.handler_obj.respond_to?(:configurable?)
    self.handler_obj.configurable?
  end

  def self.sources
    DomainLogSource.find(:all, :conditions => {:active => true}, :order => 'position')
  end

  def self.traffic_scope(from, duration, opts={})
    scope = DomainLogSession.valid_sessions.between(from, from+duration).hits_n_visits('domain_log_source_id')
    if opts[:target_id]
      scope = scope.scoped(:conditions => {:domain_log_source_id => opts[:target_id]})
    end
    scope
  end

  def self.traffic(from, duration, intervals, opts={})
    DomainLogSession.update_sessions_for from, duration, intervals

    DomainLogGroup.stats(self.name, from, duration, intervals, :type => 'traffic') do |from, duration|
      self.traffic_scope from, duration, opts
    end
  end

  class AffiliateOptions < HashModel
    def matches?(session)
      session.affiliate.blank? ? false : true
    end
  end

  class EmailCampaignOptions < HashModel
    def matches?(session)
      return Module.const_get('MarketCampaignQueueSession').find_by_session_id(session.session_id) ? true : false
      rescue NameError
      return false
    end
  end

  class SocialNetworkOptions < HashModel
    attributes :sites => nil

    def matches?(session)
      return false unless session.domain_log_referrer

      self.sites.each do |site|
        return true if session.domain_log_referrer.referrer_domain.include?(site)
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
      ['.facebook.com', '.myspace.com']
    end

    def configurable?; true; end

    options_form(
                 fld(:social_networks, :text_area)
                 )
  end

  class SearchOptions < HashModel
    def matches?(session)
      session.query.blank? ? false : true
    end
  end

  class ReferrerOptions < HashModel
    def matches?(session)
      session.domain_log_referrer ? true : false
    end
  end

  class TypeInOptions < HashModel
    def matches?(session); true; end
  end
end
