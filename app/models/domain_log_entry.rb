# Copyright (C) 2009 Pascal Rettig.

class DomainLogEntry < DomainModel
  
  belongs_to :user,:class_name => "EndUser",:foreign_key => 'user_id'
  belongs_to :end_user_action
  belongs_to :domain_log_session
  belongs_to :content_node
  belongs_to :site_version
  belongs_to :user_class
  belongs_to :site_node

  named_scope :recent, lambda { |from| from ||= 1.minute.ago; {:conditions => ['occurred_at > ?', from]} }
  named_scope :between, lambda { |from, to| {:conditions => ['`domain_log_entries`.occurred_at >= ? AND `domain_log_entries`.occurred_at < ?', from, to]} }
  named_scope :content_only, :conditions => 'content_node_id IS NOT NULL'
  named_scope :hits_n_visits, lambda { |group_by|
    group_by ? {:select => "#{group_by} as target_id, count(*) AS hits, count( DISTINCT domain_log_session_id ) AS visits, SUM(IF(domain_log_entries.user_level=3,1, 0)) AS subscribers, SUM(IF(domain_log_entries.user_level=4,1, 0)) AS leads, SUM(IF(domain_log_entries.user_level=5,1, 0)) AS conversions, SUM(`value`) as total_value", :group => 'target_id'} : {:select => "count(*) AS hits, count( DISTINCT domain_log_session_id ) AS visits, SUM(IF(domain_log_entries.user_level=3,1, 0)) AS subscribers, SUM(IF(domain_log_entries.user_level=4,1, 0)) AS leads, SUM(IF(domain_log_entries.user_level=5,1, 0)) AS conversions, SUM(`value`) as total_value"}
  }
  named_scope :valid_sessions, :conditions => 'domain_log_sessions.`ignore` = 0 AND domain_log_sessions.domain_log_source_id IS NOT NULL', :joins => :domain_log_session

  def self.create_entry_from_request(user, site_node, path, request, session, output)
    return nil unless request.session_options

    action = output.paction if output && output.paction
    self.create_entry(user, 
                      site_node, 
                      path, 
                      session[:domain_log_session] ? session[:domain_log_session][:id] : nil, 
                      output ? output.status.to_i : nil, 
                      action,
                      (output && output.page? && output.content_nodes) ? output.content_nodes[0] : nil,
                      (output && (output.page? || output.redirect?)) ? output.user_level : nil,
                      (output && (output.page? || output.redirect?)) ? output.user_value : nil)
  end

  def self.create_entry(user,site_node,path,domain_log_session_id,http_status,action=nil,content_node_id=nil,user_level=nil,user_value=nil)
    entry = DomainLogEntry.create(
      :user_id => user.id,
      :user_class_id => user.user_profile_id,
      :site_node_id => site_node ? site_node.id : nil,
      :site_version_id => site_node ? site_node.site_version_id : nil,
      :domain_id => DomainModel.active_domain_id,
      :node_path => site_node ? site_node.node_path : nil,
      :page_path => path,
      :occurred_at => Time.now(),
      :domain_log_session_id => domain_log_session_id,
      :content_node_id => content_node_id,
      :http_status => http_status,
      :end_user_action_id => action.is_a?(EndUserAction) ? action.id : nil,
      :user_level => user_level,
      :value => user_value)
    entry.domain_log_session.update_attribute(:user_level, user_level) if user_level && entry.domain_log_session.user_level.to_i < user_level
    entry
  end
  
  def action
    if self.end_user_action
      self.end_user_action.description
    else 
      nil
    end
  
  end
  
  def user?
    self.user_id != nil && self.user
  end

  def username
    user? ? self.user.name : 'Anonymous'.t
  end

  def url
    self.node_path.to_s + (self.page_path.blank? ? '' : "/" + self.page_path.to_s)
  end

  def self.find_user_sessions(user)
    # If we have a user, find any other sessions
    entry_sessions = 
        DomainLogEntry.find(:all,
            :conditions => ["user_id=?",user.id],
            :group => 'domain_log_session_id',
            :select => 'domain_log_session_id',
            :order => 'occurred_at DESC').map do |entry|
              entry.domain_log_session_id
        end
    
    find_session_helper(entry_sessions)
  end
  
  def self.find_anonymous_session(domain_log_session_id)      
    entry_sessions = [ domain_log_session_id ]
  
    find_session_helper(entry_sessions)
  end    
  
  
  def self.find_session_helper(entry_sessions)
    # Get rid of duplicates
    entry_sessions.uniq!
    
    entries = []
    page_count = 0
    entry_sessions.each_with_index do |domain_log_session_id,idx|
      session_entries = DomainLogEntry.find(:all,:conditions => {:domain_log_session_id => domain_log_session_id},:order => 'occurred_at')
      page_count += session_entries.length
      entries << { :session =>  (entry_sessions.length - idx).to_i,
                   :occurred_at => session_entries[0].occurred_at, 
                   :domain_log_session_id => domain_log_session_id,
                   :pages => session_entries.length,
                   :last_page_at => session_entries[-1].occurred_at
                  }
      entries += session_entries
    end  
    
    [ {:page_count => page_count, :session_count => entry_sessions.length }, entries ]
  end

# No longer works, the actual session_id is not in the entries table anymore
#
#  def self.create_sessions!
#    offset = 0
#    limit = 100
#    done = false
#    while(!done)
#      entries = self.find(:all,:offset => offset,:limit => limit,:order => 'occurred_at')
#      DomainLogSession.record_timestamps = false
#
#      entries.each do |entry|
#        ses = DomainLogSession.session(entry.domain_log_session_id,entry.user_id,entry.ip_address,false)
#        ses.created_at = entry.occurred_at if ses.created_at.blank?
#        ses.save
#      end
#      offset+=limit
#      DomainLogSession.record_timestamps = true
#    
#      done = true if entries.length < limit
#    end
#    
#    
#    
#    
#  end

  def self.traffic(from, duration, intervals, opts={})
    DomainLogGroup.stats(self.name, from, duration, intervals, :type => 'traffic') do |from, duration|
      DomainLogEntry.valid_sessions.between(from, from+duration).hits_n_visits nil
    end
  end

  def self.user_sessions(end_user_id)
    sessions = DomainLogSession.find :all, :conditions => {:end_user_id => end_user_id}, :include => [:domain_log_referrer, :domain_log_visitor]
    visitor_ids = DomainLogVisitor.find(:all, :select => :id, :conditions => {:end_user_id => end_user_id}).collect(&:id)
    sessions += DomainLogSession.find(:all, :conditions => ['domain_log_visitor_id in(?) && (end_user_id IS NULL || end_user_id = ?)', visitor_ids, end_user_id], :include => [:domain_log_referrer, :domain_log_visitor]) unless visitor_ids.empty?
    sessions = sessions.uniq.sort { |a,b| b.created_at <=> a.created_at }
    DomainLogSession.update_sessions sessions
    sessions
  end
end
