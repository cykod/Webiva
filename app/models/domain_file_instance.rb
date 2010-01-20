# Copyright (C) 2009 Pascal Rettig.


# DomainFileInstances represent a single usage of a DomainFile
# on the site. See ModelExtension::FileInstanceExtension for more details
class DomainFileInstance < DomainModel

  belongs_to :domain_file
  
  belongs_to :target, :polymorphic => true
  
  # DomainFile - when a file is destroyed, asks if you really want to delete as it's used in XXX places
  # Delete a folder - same thing
  
  # new version of file - update all the places it's used. 
  
  # Clear one or more target of specific classes
  # without instantiating them
  def self.clear_targets(target_type,target_id)
    self.delete_all({ :target_type => target_type, :target_id => target_id })
  end
end
