# Copyright (C) 2009 Pascal Rettig.


class Manage::DomainsController < CmsController # :nodoc: all

  # All client users can access this controller
  # but specific functions are permitted only by the system or client admins
  permit 'client_admin'

  protected 
  before_filter :validate_admin
  def validate_admin
    unless myself.client_user.system_admin?
      redirect_to :controller => '/manage/system'
      return false
    end
    
  end

  before_filter :validate_domain, :except => [ :index, :domains_table, :add ]
  def validate_domain
   @domain = Domain.find(params[:path][0])

    # Make sure we're editing our own domain
    if !myself.has_role?('system_admin') &&  myself.client_user.client_id != @domain.client_id
      redirect_to :action => 'index'
      return
    end
  end

  public

  layout "manage"
  
    # need to include 
   include ActiveTable::Controller   
   active_table :domains_table,
                Domain,
                [ ActiveTable::StringHeader.new('domains.name',:label => 'Domain Name'),
                  ActiveTable::StaticHeader.new('Client'),
                  ActiveTable::StaticHeader.new('Type'),
                  ActiveTable::StaticHeader.new('Status'),
                  ActiveTable::StaticHeader.new('Goto'),
                  ActiveTable::StaticHeader.new('Delete')

                ]

  def domains_table(display=true)

    if myself.has_role?('system_admin')
      @active_table_output = domains_table_generate params, :include => 'client'
    else
      
      @active_table_output = domains_table_generate params, :include => 'client', :conditions => [ "client_id = ?", myself.client_user.client_id  ]
    end

    render :partial => 'domains_table' if display
  end

  def index
    cms_page_info [ ['System',url_for(:controller => '/manage/system')], 'Domains'],'system'
    
    domains_table(false)
    render :action => 'list'
  end
  
  def edit
  
 
    
    cms_page_info [ ['System',url_for(:controller => '/manage/system')], ['Domains',url_for(:controller => '/manage/domains')], ['Edit %s',nil,@domain.name] ],'system'

    case @domain.status
    when 'initializing':
      flash[:notice] = 'Domain is currently initializing and cannot be edited'
      redirect_to :action => 'index'
      return
    when 'setup':
      redirect_to :action => 'setup', :path => @domain.id
      return
    end
    
    if @domain.domain_type == 'redirect'
      if request.post?  && params[:domain][:redirect]
        @domain.update_attribute(:redirect,params[:domain][:redirect])
      end
    else
      if request.post? && params[:domain][:email_enabled]
        @domain.update_attributes(:email_enabled => params[:domain][:email_enabled],
                                  :ssl_enabled => params[:domain][:ssl_enabled])
        
        if @domain.email_enabled
          DomainEmail.setup_domain_emails
        end
        flash.now[:notice] = 'Updated Domain Options'
      end
      @domain_modules = DomainModule.all_modules(@domain)
      @domain_modules = @domain_modules.sort { |a,b| a[:name] <=> b[:name] }
    end
  end

  def update_module
    
    if request.post?
      mod = params[:mod]
      
      entry = @domain.domain_modules.find_by_name(mod) || @domain.domain_modules.build(:name => mod)
      entry.access = params[:access] == 'available' ? 'available' : 'unavailable'
      entry.save
    end
    
    redirect_to :action => 'edit', :path => @domain.id
  end
  
  def make_unavailable
    
    mod = params[:mod]
    
    entry = @domain.domain_modules.find_by_name(mod) || @domain.domain_modules.create(:name => mod)
    entry.access ='available'
    entry.save
    
    redirect_to :action => 'edit', :path => @domain.id
  end
  
  
  def add
    cms_page_info [ ['System',url_for(:controller => '/manage/system')], ['Domains',url_for(:controller => '/manage/domains')], 'Add Domain'],'system'

    if myself.client_user.system_admin? || myself.client_user.client.domains.count < myself.client_user.client.domain_limit
      @domain = Domain.new
    else
      flash[:notice] = 'Domain Limit Reached'
      redirect_to :action => 'index'
      return
    end
    
    if request.post? && params[:domain]

      if params[:commit]
        @domain = Domain.new(params[:domain])
        
        # Override the client unless we are a system administrator
        @domain.client = myself.client_user.client unless myself.client_user.system_admin?
        @domain.status = 'setup'
        if @domain.save
          redirect_to :action => 'setup', :path => @domain.id
          return 
        end
      else
        redirect_to  :action => 'index'
        return
      end
    end
    
    @clients = Client.find(:all, :order => 'name').collect { |clt| [clt.name,clt.id] }  if myself.client_user.system_admin?
  
  end
  
  def setup
    cms_page_info [ ['System',url_for(:controller => '/manage/system')], ['Domains',url_for(:controller => '/manage/domains')], 'Domain Setup'],'system'
    
    @domain = Domain.find(params[:path][0])
    
    case @domain.status
    when 'initializing':
      flash[:notice] = 'Domain is currently initializing and cannot be edited'
      redirect_to :action => 'index'
      return
    when 'initialized':
      redirect_to :action => 'edit', :path => @domain.id
      return
    end
    
    if request.post? && params[:domain]
      if @domain.domain_type == 'domain'
	if params[:domain][:database] == 'create'
          @domain.attributes = params[:domain].slice(:www_prefix,:active)
	  @domain.status = 'initializing'
	  @domain.save
	  DomainModel.run_worker('Domain',@domain.id,'initialize_database')
	  flash[:notice] = 'Initializing the %s Domain' / @domain.name
	  redirect_to :action => 'index'
	  return
	else
	  @copy_domain = @domain.client.domains.find_by_id(params[:domain][:database])
	  if @copy_domain
	    @domain.database = @copy_domain.database
	    @domain.file_store = @copy_domain.file_store
	    @domain.status = 'initialized'
	    @domain.save
	    flash[:notice] = 'Initialized the %s Domain' / @domain.name
	    redirect_to :action =>'index'
	    return
	  end
	end
      elsif @domain.domain_type == 'redirect'
        flash[:notice] = "%s has been setup" / @domain.name
        @domain.redirect = params[:domain][:redirect]
        @domain.status = 'initialized'
        @domain.save
        redirect_to :action => 'index'
        return
      end
    end
    
    domains = @domain.client.domains.find(:all,:conditions => '`database` IS NOT NULL AND `database` != ""',:group => '`database`',:order => 'domains.id')
    @database_options = [ [ 'Create new Database', 'create' ] ] + domains.collect { |dmn| [ 'Share %s Database' / dmn.name, dmn.id ] } 
  end

  def delete
    cms_page_info [ ['System',url_for(:controller => '/manage/system')], ['Domains',url_for(:controller => '/manage/domains')], 'Delete Domain'],'system'

  end

  def destroy
    
    if request.method == :post

      if @domain
        @domain.destroy

        flash[:notice] = "Deleted Domain #{@domain.name}"
        redirect_to :action => "index"
        return
      end

    end
    flash[:notice] = 'Could not delete domain'
    redirect_to :action => "index"

  end

end
