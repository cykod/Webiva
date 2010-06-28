# Copyright (C) 2009 Pascal Rettig.

# Base class for all active record models that exist in the primary Webiva database.
class SystemModel < ActiveRecord::Base
  self.abstract_class = true

  # Generates a random hexdigest hash
  def self.generate_hash
     Digest::SHA1.hexdigest(Time.now.to_i.to_s + rand(1e100).to_s)
  end
end
