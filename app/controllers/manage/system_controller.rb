# Copyright (C) 2009 Pascal Rettig.

class Manage::SystemController < CmsController # :nodoc: all

  permit ['system_admin','client_admin']
  layout 'manage'

  def index
    cms_page_info("System Configuration",'system')
  
    @client_user = myself.client_user
    render :action => 'index' 
  end
end
