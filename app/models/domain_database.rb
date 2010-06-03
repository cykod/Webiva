require 'sha1'
require 'logger'

class DomainDatabase < SystemModel
  belongs_to :client

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_presence_of :options

  serialize :options

  def after_save #:nodoc:
    # Clear the domain information out of any cache
    Domain.find(:all, :conditions => {:domain_database_id => self.id}).each do |domain|
      DataCache.set_domain_info(domain.name,nil)
    end
  end
end
