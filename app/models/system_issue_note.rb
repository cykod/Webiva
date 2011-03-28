# Copyright (C) 2009 Pascal Rettig.

class SystemIssueNote < SystemModel #:nodoc:all
  
  belongs_to :system_issue
  belongs_to :entered_user, :polymorphic => true
  
  belongs_to :domain_file
  
  validates_presence_of :action
  
  after_create :send_issue

  def send_issue
    SystemIssueMailer.deliver_issue(self.system_issue.reload,'updated')
  end
end
