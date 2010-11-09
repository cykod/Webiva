
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
    scope = DomainLogSession.valid_sessions.between(from, from+duration)
    if opts[:target_id]
      scope = scope.scoped(:conditions => {:domain_log_referrer_id => opts[:target_id]}).hits_n_visits('domain_log_referrer_id')
    elsif opts[:domain]
      scope = scope.scoped(:joins => :domain_log_referrer, :conditions => ['`domain_log_referrers`.`referrer_domain` = ?', opts[:domain]]).hits_n_visits('`domain_log_referrers`.referrer_path')
    else
      scope = scope.referrer_only.hits_n_visits('domain_log_referrer_id')
    end
    scope
  end

  def self.traffic(from, duration, intervals, opts={})
    type = 'traffic'
    group = nil
    if opts[:domain]
      type += "_#{opts[:domain]}"
      group = 'referrer_path'
    end
    has_target_entry = group ? true : false

    DomainLogGroup.stats(self.name, from, duration, intervals, :type => type, :group => group, :has_target_entry => has_target_entry) do |from, duration|
      DomainLogSession.update_sessions_for from, duration, 1
      self.traffic_scope from, duration, opts
    end
  end
end
