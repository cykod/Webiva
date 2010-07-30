require 'sha1'
require 'logger'

class DomainDatabase < SystemModel
  DEFAULT_MAX_FILE_STORAGE = 10.gigabytes / 1.megabyte

  belongs_to :client
  has_many :domains, :order => :id

  validates_uniqueness_of :name, :allow_blank => true
  validates_presence_of :client_id

  validates_numericality_of :max_file_storage

  serialize :options
  serialize :config

  def  before_validation_on_create
    self.max_file_storage = DomainDatabase::DEFAULT_MAX_FILE_STORAGE unless self.max_file_storage
  end

  def validate
    self.errors.add(:max_file_storage, 'is too large') if self.client && self.max_file_storage > self.client.available_file_storage(self)
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
    self.first_domain ? self.first_domain.name : self.name
  end

  def options
    opt = self.read_attribute(:options)
    return opt if opt
    database_file = "#{RAILS_ROOT}/config/sites/#{self.name}.yml"
    return nil unless File.exists?(database_file)
    info = YAML.load_file(database_file)
    self.update_attribute(:options, info) if self.id
    info
  end
end
