require 'sha1'
require 'logger'

class DomainDatabase < SystemModel
  DEFAULT_MAX_FILE_STORAGE = 10.gigabytes / 1.megabyte

  belongs_to :client
  has_many :domains, :order => :id

  validates_uniqueness_of :name, :allow_blank => true
  validates_presence_of :client_id

  validates_numericality_of :max_file_storage
  validate :validate_storage
  
  serialize :options
  serialize :config

  after_save :update_domains
  
  before_validation(:on => :create) { self.max_file_storage ||= DomainDatabase::DEFAULT_MAX_FILE_STORAGE }

  def validate_storage
    self.errors.add(:max_file_storage, 'is too large') if self.client && self.max_file_storage > self.client.available_file_storage(self)
  end

  def update_domains #:nodoc:
    # Clear the domain information out of any cache
    self.domains.each do |domain|
      DataCache.set_domain_info(domain.name,nil)
    end
  end

  def first_domain
    @first_domain ||= self.domains[0]
  end

  def domain_name
    self.first_domain ? self.first_domain.name : self.name
  end

  def options
    opt = self.read_attribute(:options)
    return opt if opt
    database_file = "#{Rails.root}/config/sites/#{self.name}.yml"
    return nil unless File.exists?(database_file)
    info = YAML.load_file(database_file)
    self.update_attribute(:options, info) if self.id
    info
  end
end
