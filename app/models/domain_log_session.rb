# Copyright (C) 2009 Pascal Rettig.



class DomainLogSession < DomainModel
  belongs_to :end_user
  
  
#  validates_uniqueness_of :session_id
  def self.session(session_id,user,ip_address,save_entry=true)
    user = user.id if user.is_a?(EndUser)
    returning (self.find_by_session_id(session_id) || self.new(:session_id => session_id, :ip_address => ip_address)) do |ses|
      ses.attributes = {:end_user_id => user}
      ses.save if save_entry
    end 
    
  end
  
  def page_count(force = false)
    atr =  self.read_attribute(:page_count)
    if atr.blank? || force
      DomainLogEntry.count(:all,:conditions => { :session_id => self.session_id })
    else
      atr
    end
  end

  
  def last_entry_at(force = false)
    atr = self.read_attribute(:last_entry_at)
    if atr.blank? || force
      DomainLogEntry.maximum(:occurred_at,:conditions => { :session_id => self.session_id })
    else  
      atr
    end
    
  end
  
  def length(force = false)
    atr = self.read_attribute(:length)
    if atr.blank? || force
      last = self.last_entry_at
      last ? (last - self.created_at).to_i : 0
    else
      atr
    end
  end
  
  def calculate!
    self.update_attributes(:page_count => self.page_count(true),:last_entry_at => self.last_entry_at(true),:length => self.length(true))
  end
  
  
end
