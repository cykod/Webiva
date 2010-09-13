# Copyright (C) 2009 Pascal Rettig.

class Manage::SystemController < CmsController # :nodoc: all

  permit ['system_admin','client_admin']
  layout 'manage'

  def index
    cms_page_info("System Configuration",'system')


    @subpages = [
       [ "Translation", :system_admin, "system_translation.png",
         { :controller => '/manage/translate' }, 
        "Translate the backend interface"
       ],
       [ "Clients", :system_admin, "system_clients.png",
         { :controller => '/manage/clients'}, 
        "Configure the client accounts on the system"
       ],
       [ "Client\nUsers", :client_admin, "system_client_users.png",
         {  :controller => '/manage/users'  }, 
        "Manage client level users"
       ],
       [ "Domains", :client_admin, "system_domains.png",
         {  :controller => '/manage/domains' }, 
        "View domains and edit options and components"
       ],
       [ "Issue Tracker", :system_admin, "system_issue_tracker.png",
         {  :controller => '/manage/issues' },
         "View issues that the system has reported"
       ]
     ]

    
  
    @client_user = self.client_user
    render :action => 'index' 
  end

  module Base
    def client
      myself.client
    end

    def client_user
      myself.client_user
    end

    def system_admin?
      self.client_user.system_admin?
    end

    def client_admin?
      self.system_admin? || self.client_user.client_admin?
    end
  end

  protected
  include Base
end
