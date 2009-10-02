# Copyright (C) 2009 Pascal Rettig.

class DomainLogEntry < DomainModel
  
  belongs_to :user,:class_name => "EndUser",:foreign_key => 'user_id'
  belongs_to :end_user_action
  
  def self.create_entry(user,site_node,path,ip_address,session_id,status,action=nil )
  
  
    # Don't track ClientUser access
    unless user.is_a?(ClientUser)
      DomainLogEntry.create(
          :user_id => user.id,
          :user_class_id => user.user_profile_id,
          :site_node_id => site_node ? site_node.id : nil,
          :node_path => site_node ? site_node.node_path : nil,
          :page_path => path,
          :occurred_at => Time.now(),
          :ip_address => ip_address,
          :session_id => session_id,
          :status => status,
          :end_user_action_id => action.is_a?(EndUserAction) ? action.id : nil)
    end
  end
  
  def action
    if self.end_user_action
      self.end_user_action.description
    else 
      nil
    end
  
  end
  
  def user?
    return self.user_id != nil
  end
  
  
  def self.find_user_sessions(user)
    # If we have a user, find any other sessions
    entry_sessions = 
        DomainLogEntry.find(:all,
            :conditions => ["user_id=?",user.id],
            :group => 'session_id',
            :select => 'session_id',
            :order => 'occurred_at DESC').map do |entry|
              entry.session_id
        end
    
    find_session_helper(entry_sessions)
  end
  
  def self.find_anonymous_session(session_id)      
    entry_sessions = [ session_id ]
  
    find_session_helper(entry_sessions)
  end    
  
  
  def self.find_session_helper(entry_sessions)
    # Get rid of duplicates
    entry_sessions.uniq!
    
    entries = []
    page_count = 0
    entry_sessions.each_with_index do |session_id,idx|
      session_entries = DomainLogEntry.find(:all,:conditions => ['session_id=?',session_id],:order => 'occurred_at')
      page_count += session_entries.length
      entries << { :session =>  (entry_sessions.length - idx).to_i,
                   :occurred_at => session_entries[0].occurred_at, 
                   :session_id => session_id ,
                   :pages => session_entries.length,
                   :last_page_at => session_entries[-1].occurred_at
                  }
      entries += session_entries
    end  
    
    [ {:page_count => page_count, :session_count => entry_sessions.length }, entries ]
  end
  
  def self.create_sessions!
    offset = 0
    limit = 100
    done = false
    while(!done)
      entries = self.find(:all,:offset => offset,:limit => limit,:order => 'occurred_at')
      DomainLogSession.record_timestamps = false

      entries.each do |entry|
        ses = DomainLogSession.session(entry.session_id,entry.user_id,entry.ip_address,false)
        ses.created_at = entry.occurred_at if ses.created_at.blank?
        ses.save
      end
      offset+=limit
      DomainLogSession.record_timestamps = true
    
      done = true if entries.length < limit
    end
    
    
    
    
  end
end
