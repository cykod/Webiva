# Copyright (C) 2009 Pascal Rettig.



class EditorChange < DomainModel
  
  validates_presence_of :target

  belongs_to :target, :polymorphic => true
  belongs_to :admin_user, :class_name => 'EndUser', :foreign_key => 'admin_user_id'

  serialize :edit_data
end
