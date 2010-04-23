# Copyright (C) 2009 Pascal Rettig.

class ModulesController < CmsController # :nodoc: all
  layout 'manage'
  
  permit 'editor_site_management'

  def index
    cms_page_info [ ['Options',url_for(:controller => 'options') ], 'Modules' ], 'options'
    
    @domain = Domain.find(DomainModel.active_domain_id)
    @available_modules = SiteModule.available_modules(@domain)

    @available_modules = @available_modules.sort { |a,b| a[:name] <=> b[:name] }
   
    expire_site if params[:refresh]

    if request.post? && params[:activate] && params[:modules]
      @domain = Domain.find(DomainModel.active_domain_id)

      activation_list = SiteModule.generate_activation_list(params[:modules][:activate])
      if activation_list
        session[:modules_activation_list] = SiteModule.activate_modules(activation_list)
        SiteModule.run_class_worker(:migrate_domain_components, :activation_list => activation_list)
        redirect_to :action => 'initializing'
      else
        flash.now[:notice] = "One or more of the selected modules could not be activated because it is unavailable or has missing depenencies"
      end
    elsif request.post? && params[:deactivate] && params[:modules]
      deactivation_list = SiteModule.generate_deactivation_list(params[:modules][:deactivate])
      if deactivation_list
        SiteModule.deactivate_modules(deactivation_list)
        redirect_to :action => 'index'
      else
        flash[:notice] = "One or more of the selected modules could not be deactivated because it has dependencies that are still active"
        redirect_to :action => 'index'
      end
    end
    
    if params[:content_type_generate]
      SiteModule.activated_modules.each do |mod|
        mod.admin_controller_class.content_node_type_generate
      end
      Editor::AdminController.content_node_type_generate
    end
  end
  


  def initializing
    cms_page_info [ ['Options',url_for(:controller => 'options') ], ['Modules',url_for(:action => 'index')], "Initializing" ], 'options'
    
    if !session[:modules_activation_list] &&  params[:path][0].to_i > 0
      session[:modules_activation_list] =  [ params[:path][0] ].to_i
    end
    @site_module_ids = session[:modules_activation_list]

    if !@site_module_ids
      return redirect_to :action => 'index'
    end

    @site_modules = SiteModule.find(:all,:conditions => { :id => @site_module_ids})
    
    @initializing = @site_modules.detect { |mod| mod.status == 'initializing' }

    if !@initializing
      @site_modules.map(&:post_initialization!)
      session[:modules_activation_list] = nil 
      expire_site
    else
      headers['refresh'] = "2 ;url=#{url_for :action => 'initializing'}"
    end
    
    if !@initializing && @site_modules.length == 1
      @site_module = @site_modules[0]
      if @site_module.status == 'initialized'
         if @site_module.admin_controller_class.method_defined?('options')
           redirect_to( :controller => @site_module.admin_controller, :action => 'options')
         end
      elsif @site_module.status == 'active'
        flash[:notice] = "The '%s' module has been initialized" / @site_module.display_name
        redirect_to :action => 'index'
        return
      end
    end
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
