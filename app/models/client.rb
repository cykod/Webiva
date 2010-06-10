# Copyright (C) 2009 Pascal Rettig.

# A System Model that represents a entity that owns
# one or more websites. Clients have a limit
# on the number of domains they can create
class Client < SystemModel 
  has_many :client_users, :dependent => :destroy
  has_many :domains, :dependent => :destroy
  has_many :domain_databases, :dependent => :destroy

  def num_databases
    self.domain_databases.count
  end

  def can_add_database?
    self.num_databases < self.domain_limit
  end
end
