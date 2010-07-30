# Copyright (C) 2009 Pascal Rettig.

# A System Model that represents a entity that owns
# one or more websites. Clients have a limit
# on the number of domains they can create
class Client < SystemModel
  DEFAULT_DOMAIN_LIMIT = 100
  DEFAULT_DATABASE_LIMIT = 10
  DEFAULT_MAX_CLIENTS = 10
  DEFAULT_MAX_FILE_STORAGE = 100.gigabytes / 1.megabyte

  has_many :client_users, :dependent => :destroy
  has_many :domains, :dependent => :destroy
  has_many :domain_databases, :dependent => :destroy

  validates_presence_of :name, :domain_limit, :max_client_users, :max_file_storage, :database_limit

  validates_uniqueness_of :name

  validates_numericality_of :domain_limit
  validates_numericality_of :database_limit
  validates_numericality_of :max_client_users
  validates_numericality_of :max_file_storage

  def before_validation
    self.domain_limit = Client::DEFAULT_DOMAIN_LIMIT unless self.domain_limit
    self.max_client_users = Client::DEFAULT_MAX_CLIENTS unless self.max_client_users
    self.max_file_storage = Client::DEFAULT_MAX_FILE_STORAGE unless self.max_file_storage
    self.database_limit = Client::DEFAULT_DATABASE_LIMIT unless self.database_limit
  end

  def num_databases
    self.domain_databases.count
  end

  def num_domains
    self.domains.count
  end

  def deactivate
    self.inactive=true
    self.domain_databases.each { |db| db.inactive = true }
    self.save
  end

  def activate
    self.inactive=false
    self.domain_databases.each { |db| db.inactive = false }
    self.save
  end

  def can_add_database?
    self.can_add_domain? && self.num_databases < self.database_limit
  end

  def can_add_domain?
    self.num_domains < self.domain_limit
  end

  def num_client_users
    self.client_users.count
  end

  def available_client_users
    return Client::DEFAULT_MAX_CLIENTS unless self.max_client_users
    available = self.max_client_users - self.num_client_users
    available > 0 ? available : 0
  end

  def used_file_storage(exclude=nil)
    @used_file_storage ||= self.domain_databases.find(:all).collect(&:max_file_storage).inject(0) { |a, b| a + b }

    if(exclude)
      @used_file_storage -= self.domain_databases.select { |d| d == exclude }.map(&:max_file_storage)[0].to_i
    end
    @used_file_storage
  end

  def available_file_storage(exclude = nil)
    return Client::DEFAULT_MAX_FILE_STORAGE unless self.max_file_storage
    available = self.max_file_storage - self.used_file_storage(exclude).to_i
    available > 0 ? available : 0
  end

  def domain_database_select_options
    self.domain_databases.collect { |db| [db.domain_name, db.id] }
  end

  def after_save
    self.domain_databases.map(&:save)
  end
end
