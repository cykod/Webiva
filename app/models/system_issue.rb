# Copyright (C) 2009 Pascal Rettig.

# Webiva level class that logs and aggregates exceptions in the system
# created automatically by rescue_in_public_action in ApplicationController
class SystemIssue < SystemModel
  
  validates_presence_of :location
  
  belongs_to :reporter_user, :polymorphic => true
  
  has_many :system_issue_notes, :dependent => :destroy
  
  def behavior_title
    (self.behavior.slice(/.*\n/)||self.behavior).strip()[0..100]
  end
  
  def after_create
    SystemIssueMailer.deliver_issue(self,'created')
  end
  
  # See if there's already and error of this type
  # if so return the parent error
  def self.register_child!(code_location,error_location,error_type)
      returning self.find(:first,:conditions => { :code_location => code_location, :error_type => error_type, :error_location => error_location },:lock => true) do |parent|
        parent.update_attributes(:children_count => parent.children_count.to_i + 1) if parent
      end
  end
  
end
