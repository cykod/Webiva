# Copyright (C) 2009 Pascal Rettig.

class Manage::ClientsController < CmsController # :nodoc: all

  permit 'system_admin'
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
                [ hdr(:icon, '', :width=>10),
                  hdr(:static, 'Name'),
                  hdr(:boolean, :inactive ),
                  hdr(:static, 'Databases/Limit'),
                  hdr(:static, 'Domains/Limit'),
                  hdr(:static, :max_file_storage, :label => 'Used/Max file storage')
                ]

  def display_client_table(display=true)
     active_table_action('client') do |act,client_ids|
      case act
        when 'delete': Client.destroy(client_ids)
        when 'deactivate': Client.find(client_ids).map { |c| c.deactivate }
        when 'activate': Client.find(client_ids).map { |c| c.activate } 
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
    @client = Client.new :database_limit => Client::DEFAULT_DATABASE_LIMIT, :domain_limit => Client::DEFAULT_DOMAIN_LIMIT, :max_client_users => Client::DEFAULT_MAX_CLIENTS, :max_file_storage => Client::DEFAULT_MAX_FILE_STORAGE
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
