# Copyright (C) 2009 Pascal Rettig.

class SystemIssueMailer < ActionMailer::Base #:nodoc:all

  def issue(issue_data,action = 'created')
    if action=='created'
      @subject = "#{ action == 'created' ? 'New' : 'Updated' } #{issue_data.reporting_domain} Issue ##{issue_data.id}: #{issue_data.behavior_title}"
    else
      @subject = "Updated #{issue_data.reporting_domain} Issue ##{issue_data.id} (#{ issue_data.status }): #{issue_data.behavior_title}"
    end
    @body['issue'] =  issue_data
    @recipients = CMS_SYSTEM_ADMIN_EMAIL
    @from       = Configuration.reply_to_email
    content_type 'text/html'

  end
end
