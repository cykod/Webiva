# Copyright (C) 2009 Pascal Rettig.

# A System Model that represents a entity that owns
# one or more websites. Clients have a limit
# on the number of domains they can create
class Client < SystemModel 
  has_many :client_users, :dependent => :destroy
  has_many :domains, :dependent => :destroy
  has_many :domain_databases, :dependent => :destroy

  validates_numericality_of :max_client_users, :greater_than => 0
  validates_numericality_of :max_file_storage, :greater_than => 0

  def before_validation
    self.max_client_users = 100 unless self.max_client_users
    self.max_file_storage = 100000 unless self.max_file_storage
  end

  def num_databases
    self.domain_databases.count
  end

  def can_add_database?
    self.num_databases < self.domain_limit
  end

  def num_client_users
    self.client_users.count
  end

  def available_client_users
    return 10 unless self.max_client_users
    available = self.max_client_users - self.num_client_users
    available > 0 ? available : 0
  end

  def used_file_storage
    @used_file_storage ||= self.domain_databases.find(:all).collect(&:max_file_storage).inject(0) { |a, b| a + b }
  end

  def available_file_storage
    return 10000 unless self.max_file_storage
    available = self.max_file_storage - self.used_file_storage
    available > 0 ? available : 0
  end

  def domain_database_select_options
    self.domain_databases.collect { |db| [db.domain_name, db.id] }
  end
end
