# Copyright (C) 2009 Pascal Rettig.


# A single save by an editor of a piece of content
# Used to track changes for SiteTemplates, SiteFeature's, etc.
class EditorChange < DomainModel
  
  validates_presence_of :target

  belongs_to :target, :polymorphic => true
  belongs_to :admin_user, :class_name => 'EndUser', :foreign_key => 'admin_user_id'

  serialize :edit_data
end
