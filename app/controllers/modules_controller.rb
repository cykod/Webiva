# Copyright (C) 2009 Pascal Rettig.

class ModulesController < CmsController # :nodoc: all
  layout 'manage'
  
  permit 'editor_site_management'

  def index
    cms_page_info [ ['Options',url_for(:controller => 'options') ], 'Modules' ], 'options'
    
    @domain = Domain.find(DomainModel.active_domain_id)
    @available_modules = SiteModule.available_modules(@domain)
   
    expire_site if params[:refresh]
    
    if params[:content_type_generate]
      SiteModule.activated_modules.each do |mod|
        mod.admin_controller_class.content_node_type_generate
      end
      Editor::AdminController.content_node_type_generate
    end
  end
  
  def update_module
    if request.post?
      mod = params[:mod]
      status = params[:status]
      
      @domain = Domain.find(DomainModel.active_domain_id)

      if status == 'active' 
        if(@site_module = SiteModule.activate_module(@domain,mod))
          DomainModel.run_worker('SiteModule',@site_module.id,'migrate_domain_component' )
          redirect_to :action => 'initializing', :path => @site_module.id
          return
        end
      else
        SiteModule.deactivate_module(@domain,mod)
        expire_site
      end
    end
    
    redirect_to :action => :index 
  end

  def initializing
    cms_page_info [ ['Options',url_for(:controller => 'options') ], 'Modules' ], 'options'
    
    @site_module = SiteModule.find(params[:path][0])
    
    if @site_module.status == 'initialized'
      if  @site_module.status == 'initialized' && @site_module.admin_controller_class.method_defined?('options')
        redirect_to :controller => @site_module.admin_controller, :action => 'options', :first => true
        return
      else
        @site_module.update_attribute(:status,'active')
        expire_site
        flash[:notice] = "The '%s' module has been initialized" / @site_module.display_name
        redirect_to :action => 'index'
        return
      end
    elsif @site_module.status != 'initializing'
      redirect_to :action => 'index'
    end
    headers['refresh'] = "2 ;url=#{url_for :action => 'initializing', :path => @site_module.id}"
    
  end
  
  def edit
    mod = SiteModule.find_by_name_and_status(params[:path][0],['active','initialized'])
    
    if(mod)
       redirect_to :controller => mod.admin_controller, :action => 'options'
    else
      redirect_to :action=> :index
    end
  end
end
