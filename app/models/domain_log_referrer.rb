
class DomainLogReferrer  < DomainModel
  validates_presence_of :referrer_domain
  
  has_many :domain_log_referrer_entries, :dependent => :delete_all

  named_scope :matching do |domain,path|
    { :conditions => { :referrer_domain => domain,
                       :referrer_path => path } }
  end

  def self.fetch_referrer(domain,path)
    self.matching(domain,path).first || self.create(:referrer_domain => domain,:referrer_path =>path)
  end

  def self.traffic_scope(from, duration, domain_log_referrer_id=nil)
    scope = DomainLogSession.between(from, from+duration).visits('domain_log_referrer_id')
    if domain_log_referrer_id
      scope = scope.scoped(:conditions => {:domain_log_referrer_id => domain_log_referrer_id})
    else
      scope = scope.referrer_only
    end
    scope
  end

  def self.traffic(from, duration, intervals, target=nil)
    DomainLogGroup.stats(target ? target : self.name, from, duration, intervals, :type => 'traffic') do |from, duration|
      self.traffic_scope from, duration, target ? target.id : nil
    end
  end
end
