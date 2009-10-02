# Copyright (C) 2009 Pascal Rettig.

class Client < SystemModel 
  # has many users, which need to be deleted
  # if we delete this client
  has_many :client_users, :dependent => :destroy
  # same for domains
  has_many :domains, :dependent => :destroy

  has_many :access_groups
end
