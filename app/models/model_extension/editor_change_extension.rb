# Copyright (C) 2009 Pascal Rettig.



module ModelExtension::EditorChangeExtension

  module ClassMethods
  
    def track_editor_changes
      after_save :editor_change_track_changes
      attr_accessor :current_version_id
    end
    
  end
  
  def self.append_features(mod)
    super
    mod.extend ModelExtension::EditorChangeExtension::ClassMethods
  end
  
  def editor_change_track_changes
    EditorChange.create(:edit_data => self.attributes.to_hash,
                        :target => self,
                        :admin_user => self.admin_user)
  end
  
  
  def version_list(limit = 30)
    EditorChange.find(:all,:include => 'admin_user', :conditions => { :target_type => self.class.to_s, :target_id => self.id },:order => 'editor_changes.created_at DESC',:limit => limit, :offset => 1)
  end
  
  def version_list_options(limit = 30)
    self.version_list.map { |elm| [ "Saved #{elm.created_at.localize(DEFAULT_DATETIME_FORMAT.t)} by #{elm.admin_user ? elm.admin_user.name : 'Unknown'}", elm.id ] }
  end
  
  def load_version(version_id)
    version = EditorChange.find_by_id(version_id,:conditions => { :target_type => self.class.to_s, :target_id => self.id })
    if version
      self.attributes = version.edit_data
      self.current_version_id = version.id
      return true
    end
    return false
  end
  

end
