
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
end
