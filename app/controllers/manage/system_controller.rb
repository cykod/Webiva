# Copyright (C) 2009 Pascal Rettig.

class Manage::SystemController < CmsController # :nodoc: all

  permit ['system_admin','client_admin']
  layout 'manage'

  def index
    cms_page_info("System Configuration",'system')
  
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
