# Copyright (C) 2009 Pascal Rettig.

class Manage::ClientsController < CmsController # :nodoc: all

  # Only system administrators can access this controller
  permit 'client_user'
  
  before_filter :validate_admin
  def validate_admin
    unless myself.client_user.system_admin?
      redirect_to :controller => '/manage/system'
      return false
    end
    
  end

  layout 'manage'

  def index
    list
    render :action => 'list'
  end

  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  # need to include 
   include ActiveTable::Controller   
   active_table :client_table,
                Client,
                [ ActiveTable::IconHeader.new('', :width=>10),
                  ActiveTable::StringHeader.new('clients.name',:label => 'Name'),
                  ActiveTable::StaticHeader.new('Domains/Limit')
                ]

  def display_client_table(display=true)
     active_table_action('client') do |act,client_ids|
      case act
        when 'delete':
          Client.destroy(client_ids)
        end
     end


    @active_table_output = client_table_generate params, :order => 'clients.name'

    render :partial => 'client_table' if display
  end

  def list
    cms_page_info [ ["System",url_for(:controller => '/manage/system',:action => 'index') ], "Clients" ],"system"

    display_client_table(false)
  end

  def new
    cms_page_info [ ["System",url_for(:controller => '/manage/system',:action => 'index') ], 
                    [ "Clients", url_for(:action => 'index') ],
                    "New Client"
                 ],"system"
    @client = Client.new
  end

  def create
    cms_page_info [ ["System",url_for(:controller => '/system',:action => 'index') ], 
                    [ "Clients", url_for(:action => 'index') ],
                    "Edit Client"
                 ],"system"
    @client = Client.new(params[:client])
    if @client.save
      flash[:notice] = 'Client was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
   cms_page_info [ ["System",url_for(:controller => '/manage/system',:action => 'index') ], ["Clients",url_for(:controller => '/manage/clients') ], 'Edit Client' ],"system"
    @client = Client.find(params[:path][0])
  end

  def update
    cms_page_info "Clients","system"
    @client = Client.find(params[:path][0])
    if @client.update_attributes(params[:client])
      flash[:notice] = 'Client was successfully updated.'
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

  def destroy
    Client.find(params[:path][0]).destroy
    myself.client.reload

    redirect_to :action => 'list'
  end

end
