# Copyright (C) 2009 Pascal Rettig.



class FeedCache < DomainModel
  set_table_name 'cached_feeds'

  def self.set_up_correctly?; true;  end
  
  
  def self.initialize_cache; end
  def self.connected?; true; end
  def self.table_exists?; true; end
  
end
