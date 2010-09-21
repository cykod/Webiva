
class DomainLogReferrer  < DomainModel
  validates_presence_of :referrer_domain
  
  has_many :domain_log_sessions

  named_scope :matching, lambda { |domain, path| {:conditions => {:referrer_domain => domain, :referrer_path => path}} }

  def self.fetch_referrer(domain,path)
    self.matching(domain,path).first || self.create(:referrer_domain => domain,:referrer_path =>path)
  end

  def title
    "#{self.referrer_domain}#{self.referrer_path}"
  end

  def admin_url
    nil
  end

  def self.chart_traffic_handler_info
    {
      :name => 'Referrer Traffic',
      :icon => 'traffic_referrer.png',
      :url => { :controller => '/emarketing', :action => 'charts', :path => ['traffic'] + self.name.underscore.split('/') }
    }
  end

  def self.traffic_scope(from, duration, opts={})
    scope = DomainLogSession.between(from, from+duration).hits_n_visits('domain_log_referrer_id')
    if opts[:target_id]
      scope = scope.scoped(:conditions => {:domain_log_referrer_id => opts[:target_id]})
    else
      scope = scope.referrer_only
    end
    scope
  end

  def self.traffic(from, duration, intervals, opts={})
    DomainLogSession.update_sessions_for from, duration, intervals

    DomainLogGroup.stats(self.name, from, duration, intervals, :type => 'traffic') do |from, duration|
      self.traffic_scope from, duration, opts
    end
  end
end
