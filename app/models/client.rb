# Copyright (C) 2009 Pascal Rettig.

# A System Model that represents a entity that owns
# one or more websites. Clients have a limit
# on the number of domains they can create
class Client < SystemModel 
  has_many :client_users, :dependent => :destroy
  has_many :domains, :dependent => :destroy
end
