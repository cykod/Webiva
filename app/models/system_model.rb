# Copyright (C) 2009 Pascal Rettig.

# Base class for all active record models that exist in the primary Webiva database.
class SystemModel < ActiveRecord::Base
  self.abstract_class = true
end
