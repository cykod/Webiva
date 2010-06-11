require 'sha1'
require 'logger'

class DomainDatabase < SystemModel
  belongs_to :client
  has_many :domains

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_numericality_of :max_file_storage

  serialize :options

  def  before_validation_on_create
    self.max_file_storage = 10000 unless self.max_file_storage
  end

  def validate
    self.errors.add(:max_file_storage, 'is too large') if self.max_file_storage > self.client.available_file_storage
  end

  def after_save #:nodoc:
    # Clear the domain information out of any cache
    self.domains.each do |domain|
      DataCache.set_domain_info(domain.name,nil)
    end
  end

  def first_domain
    @first_domain ||= self.domains[0]
  end

  def domain_name
    self.first_domain.name
  end
end
