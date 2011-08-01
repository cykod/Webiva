# Copyright (C) 2009 Pascal Rettig.



module ModelExtension::EditorChangeExtension #:nodoc:

  module ClassMethods
  
    # Call this method to automatically save a copy of this objects attributes
    # whenever the object is saved. Should be used relatively sparingly 
    # to prevent the table from getting overloaded. Does not save
    # relationships only attributes
    def track_editor_changes
      after_save :editor_change_track_changes
      attr_accessor :current_version_id
      self.send(:include,ModelExtension::EditorChangeExtension::InstanceMethods)
    end
    
  end
  
  def self.append_features(mod) #:nodoc:
    super
    mod.extend ModelExtension::EditorChangeExtension::ClassMethods
  end
  

  module InstanceMethods
    def editor_change_track_changes #:nodoc:
      EditorChange.create(:edit_data => self.attributes.to_hash,
                          :target => self,
                          :admin_user => self.admin_user)
    end
    
    # Return a list of changes on this object
    # Returns a list of EditorChange objects
    def version_list(limit = 30)
      EditorChange.find(:all,:include => 'admin_user', :conditions => { :target_type => self.class.to_s, :target_id => self.id },:order => 'editor_changes.created_at DESC',:limit => limit, :offset => 1)
    end
    
    # Return a select-friendly list of options
    def version_list_options(limit = 30)
      self.version_list.map { |elm| [ "Saved #{elm.created_at.localize(Configuration.datetime_format)} by #{elm.admin_user ? elm.admin_user.name : 'Unknown'}", elm.id ] }
    end
    
    # Load a specific version into this object 
    # 
    # Warning: calling obj.load_version(..) and obj.save 
    # will replace all the attributes for this object.
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

end
