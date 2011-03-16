# Copyright (C) 2009 Pascal Rettig.

class StructureController < CmsController  # :nodoc: all

  public
  
  permit ['editor_structure','editor_structure_advanced'], :except => [ :index, :element_info, :wizards, :wizard ]
  permit ['editor_website','editor_structure','editor_structure_advanced'], :only => [:index, :element_info]


  permit ['editor_structure_advanced'], :only => [:wizards, :wizard]

  helper :application
  
  cms_admin_paths 'website',
       'Website' => { :action => 'index' }

  
  def index 
    session[:structure_view_modifiers] = @display_modifiers= params[:modifiers] ||
      session[:structure_view_modifiers] || 
      (myself.has_role?('editor_structure_advanced') ? 'show' : 'hide')
    
    session[:structure_view_modules] = @display_modules = params[:modules] ||
      session[:structure_view_modules] ||  'hide'
    
    session[:show_archived] = @show_archived = params[:archived] ||
      session[:show_archived] || 'hide'

     @site_version_override = params[:version] 

    @version = SiteVersion.find_by_id(@site_version_override) 
    @version ||= SiteVersion.current

    
    if !myself.has_role?('editor_structure_advanced')
      @display_modifiers = session[:structure_view_modifiers] = 'hide'
      @display_modules = session[:structure_view_modules] = 'hide'
    end
    
    
    @closed = cookies[:structure].to_s.split("|").map(&:to_i)

    @site_root = @version.nested_pages(@closed)

    if @show_archived == 'hide'
      SiteVersion.remove_archived(@site_root)
    end

    
    if session[:structure_view_modules] 
      @active_modules = SiteModule.structure_modules
    end
    
    @wizard_list = get_handlers(:structure,:wizard) if myself.has_role?('editor_structure_advanced')
    @wizard_list ||= []

    require_js 'protovis/protovis-r3.2.js'
    require_js 'tipsy/jquery.tipsy.js'
    require_js 'protovis/tipsy.js'
    require_css 'tipsy/tipsy.css'
    require_js 'charts.js'
    require_js 'emarketing.js'

    view_language

    cms_page_path [], 'Website'
    #'website',myself.has_role?('editor_structure_advanced') ? 'CMSStructure.popup();' : nil
    render :action => 'view', :layout => "manage"
  end


  def wizards
    @version = SiteVersion.find(params[:version]) 
    cms_page_path [[ "Website",url_for(:controller => '/structure', :action => 'index', :version => @version.id) ]],"Wizards"

    @wizard_list = get_handler_info(:structure,:wizard) if myself.has_role?('editor_structure_advanced')
    @wizard_list ||= []
    @wizard_list = @wizard_list.select { |info| myself.has_role?(info[:permit]) }
    @wizard_list.delete_if { |info| info[:class] == Wizards::SimpleSite } if SiteModule.module_enabled?('webiva_net')
   end

  def wizard
    @version = SiteVersion.find_by_id(params[:version])
    SiteVersion.override_current(@version)

    @wizard_info = get_handler_info(:structure, :wizard, params[:path].join('/'))

    @the_wizard = @wizard_info[:class].new params[:wizard]

    @the_wizard.set_defaults(params) unless params[:wizard]

    return redirect_to(@the_wizard.setup_url) unless @the_wizard.can_run_wizard?

    cms_page_path [["Website", url_for(:controller => '/structure', :action => 'index', :version => @version.id)], ["Wizards", url_for(:controller => '/structure', :action => 'wizards', :version => @version.id)]], '%s Wizard' / @wizard_info[:name]

    if request.post?
      if ! params[:commit] 
        redirect_to :controller => '/structure', :action => 'wizards', :version => @version.id
      elsif @the_wizard.valid?
        @the_wizard.run_wizard
        flash[:notice] = '%s Wizard Finished' / @wizard_info[:name]
        redirect_to :controller => '/structure', :version => @version.id
      end
    end
  end

  def site_version
    @version = SiteVersion.find_by_id(params[:site_version]) || SiteVersion.new

    if params[:version] 
      @version.attributes = params[:version].slice(:name, :copy_site_version_id)
      
      if @version.valid?
        if @version.copy_site_version
          @version = @version.copy_site_version.copy(@version.name)
        else
          @version.save
        end
        
        if @version.id
          session[:site_version_override] = @version.id
          render(:update) { |page| page.redirect_to :action => 'index', :version => @version.id }
          return
        end
      end
    end
    render :partial => 'site_version'
  end

  def delete_tree
    @version = SiteVersion.find(params[:version_id])

    if @version && @version.can_delete?
      @version.destroy
    end

    render :nothing => true
  end
 
  def move_node
    node_id = params[:node_id]
    parent_id = params[:parent_id]
    
    node = SiteNode.find(node_id)
    parent_node = SiteNode.find(parent_id)
    
    old_path = node.node_path;

    begin
      if node && parent_node && node.parent_id != parent_node.id
        node.move_to_child_of(parent_node)
        node.reload
        node.save
        #SiteNode.update_paragraph_links(old_path,node.node_path)
      end
    rescue ActiveRecord::ActiveRecordError
      SiteNode.rebuild!
      if node && parent_node
        node.move_to_child_of(parent_node)
        node.reload
        node.save
        Configuration.log_config_error('Had to rebuild site tree')
        #SiteNode.update_paragraph_links(old_path,node.node_path)
      end
    end


    render :nothing => true
  end
  
  def add_modifier
    parent_id =params[:parent_id]
    modifier_type = params[:modifier_type]
    
    node = SiteNode.find(parent_id)
    md = node.add_modifier(modifier_type, :created_by_id => myself.id)

    view_language

    render :partial => 'site_node_modifier', :locals => { :mod => md }
  end
  
  
  def copy_node
  
    parent_id = params[:parent_id]
    node_id = params[:node_id]
    
    @node = SiteNode.find(params[:node_id])
    parent = SiteNode.find(params[:parent_id])
    
    @new_node = @node.duplicate!(parent)
    
    view_language

    render :partial => 'path', :locals => { :paths => [@new_node] }    
  end
  
  def add_node 
    parent_node = SiteNode.find(params[:parent_id])
    node_type = params[:node_type]  
    title = params[:title] || 'enter_title'

    view_language

    if(node_type == 'M')
      module_name = params[:module_name] 
      
      if SiteModule.site_node_module_active?(module_name)
      
        node = SiteNode.new({ :node_type => node_type,
                              :title => title,
                              :created_by_id => myself.id,
                              :site_version_id => parent_node.site_version_id,
                              :module_name => module_name })
      else
        render :nothing => true
        return 
      end
    else
      node = SiteNode.new({ :node_type => node_type,
                            :created_by_id => myself.id,
                            :site_version_id => parent_node.site_version_id,
                            :title => title })
    end
    
    node.save
    node.move_to_child_of(parent_node)
    
    render :partial => 'path', :locals => { :paths => [node] }
    
  end
  
  def remove_node
    node_id = params[:node_id]
    
    node = SiteNode.find(node_id)
    node.destroy

    expire_site
    
    render :nothing => true
  end
  
  def remove_modifier 
    modifier_id = params[:modifier_id]
    mod = SiteNodeModifier.find(modifier_id)
    mod.destroy

    expire_site
    
    render :nothing => true
  end
  
  def move_modifier
    mod = SiteNodeModifier.find(params[:modifier_id])
    node = SiteNode.find(params[:node_id])
    
    mod.remove_from_list
    mod.position = node.site_node_modifiers.last.position + 1
    node.site_node_modifiers << mod
    mod.move_to_top

    expire_site
    
    render :nothing => true
    
  end
  
  def edit_node_title
    node_id = params[:node_id]
    title = params[:title]
    select_node = params[:select_node].to_i == 1 ? true : false
    
    node = SiteNode.find(node_id)
    old_path = node.node_path
    node.title = title
    node.save
    
    opts = Configuration.options
    if(!opts.page_title_prefix.blank?)
      node.live_revisions.each do |rev|
        rev.update_attribute(:title,opts.page_title_prefix + node.title.humanize)
      end
    end

    #SiteNode.update_paragraph_links(old_path,node.node_path)
    
    if(select_node) 
        element_info_display('node',node.id)
    else
        render :nothing => true;
    end
  end
  
  def adjust_node
    node_id = params[:node_id]
    adjustment = params[:adjustment].to_i
    previous_id = params[:previous_id].to_i

    node = SiteNode.find(node_id)
    if previous_id > 0
      node.move_to_right_of(previous_id)
    else
      if node.parent.children.length > 1 &&  node.parent.children[0] != node
        node.move_to_left_of( node.parent.children[0])
      end
    end

    expire_site    
    
    render :nothing => true
    
      
  end
  
  def adjust_modifier
      mod_id = params[:mod_id]
      adjustment = params[:adjustment].to_i
      
      mod = SiteNodeModifier.find(mod_id)
      
      if mod
        mod.insert_at(mod.position + adjustment)
      end
      
      expire_site
      
      render :nothing => true
     
      
  end

  def element_info
  	node_type = params[:node_type]
  	node_id = params[:node_id]

   	element_info_display(node_type,node_id)
  end
  
  
  # Update a revision information
  def update_revision
    @revision = PageRevision.find(params[:revision_id])
    
    @revision.update_attributes(params[:revision_edit])
  
  
    @languages = Configuration.languages
    @node = @revision.revision_container
    @revision_info = @node.language_revisions(@languages)
    
    expire_site
    view_language
    info = @revision_info.detect { |rev| rev[0] == @view_language }

    @active_revision_info = [ @revision.language, @revision,info[2]]
    
    if @node.is_a?(SiteNode)
      render :partial => 'page_element_info'
    else
      render :partial => 'framework_modifier_info'
    end
  end
  
  def update_site_node_options
    @node = SiteNode.find(params[:path][0])
    
    node_arr = {}
    [ 'include_in_sitemap','follow_links','cache_page','index_page','archived' ].each do |atr|
      node_arr[atr] = params[:site_node][atr]
    end
    
    expire_site
    
    @node.update_attributes(node_arr)
    
    update_revision
    
    # render :partial => 'site_node_options'
  
  end
  
  def create_revision
    revision_id = params[:revision_create][:from_revision_id] if params[:revision_create]
    language = params[:language]
  
    if revision_id
      @revision = PageRevision.find(revision_id)
      @new_revision = @revision.create_translation(language)
    else
      if params[:framework_id]
        @node = SiteNodeModifier.find(params[:framework_id])
      else
        @node = SiteNode.find(params[:node_id])
      end
      
      @new_revision = @node.page_revisions.create(:language => language,
                                  :revision_type => 'real',
                                  :active => false)
      
    end

    
    @languages = Configuration.languages
    
    if @new_revision.revision_container.is_a?(SiteNode)
      @node = @new_revision.revision_container
      @revision_info = @node.language_revisions(@languages)
      @active_revision_info =  [ @new_revision.language, @new_revision, @new_revision  ]

      render :partial => 'page_element_info'
    else
      @mod =  @new_revision.revision_container
      @node = @mod.site_node
      @revision_info = @mod.language_revisions(@languages)
      @active_revision_info =  [ @new_revision.language, @new_revision,  @new_revision ] 
      render :partial => 'framework_modifier_info'
    end
    
    expire_site
  
  end

  # need to include 
  include ActiveTable::Controller
  active_table :site_nodes_table,
               SiteNode,
               [ hdr(:string, 'node_path', :label => 'Url'),
                 hdr(:static, 'Title'),
                 hdr(:static, 'Menu Title'),
                 hdr(:static, 'Meta Description'),
                 hdr(:static, 'Meta Keywords')
               ]

  def pages
    display_site_nodes_table(false)
    cms_page_path [[ "Website",url_for(:controller => '/structure', :action => 'index', :version => @version.id) ]], "Edit Pages"
  end

  def display_site_nodes_table(display=true)
    @version ||= SiteVersion.find_by_id(params[:path][0]) || SiteVersion.current
    @languages ||= Configuration.languages
    @language ||= params[:language] || 'en'

    active_table_action 'site_node' do |act,ids|
    end

    @active_table_output = site_nodes_table_generate params, :conditions => ['site_version_id = ? AND node_type = ?', @version.id, 'P'], :order => 'node_path', :per_page => 20
  
    render :partial => 'site_nodes_table' if display
  end

  def edit_page_revision
    @node = SiteNode.find params[:path][0]
    @version = @node.site_version
    @revision = @node.page_revisions.find params[:path][1]
    @language = @revision.language

    if request.post? && params[:revision]
      @revision.updated_by = myself
      if @revision.update_attributes params[:revision]
        expire_site
        render :update do |page|
          page << 'RedBox.close();'
          page << 'PageEditor.refreshList();'
        end
        return
      end
    end

    render :partial => 'edit_page_revision'
  end

  def experiment
    view_language

    @container = SiteNode.find params[:path][0]

    @new = params[:new]
    if @new
      @experiment = Experiment.new(:experiment_container => @container)
    else
      @experiment = @container.experiment || Experiment.new(:experiment_container => @container)
    end

    @experiment.language = @view_language
    @experiment.page_revision_options = @container.page_revisions.find(:all, :conditions => {:revision_type => 'real', :language => @view_language}, :select => 'revision, version_name, active', :order => :revision).collect { |r| ["#{r.active ? '*' : ''} #{r.revision} #{r.version_name}".strip, r.revision] }

    if request.post? && params[:experiment]
      @experiment.num_versions = params[:num_versions].to_i
      @experiment.attributes = params[:experiment]
      if params[:update] && @experiment.save
        @container.update_attribute :experiment_id, @experiment.id

        p_element_info @container, false

        render :update do |page|
          page << 'RedBox.close();'
          page.replace_html 'element_info', :partial => 'page_element_info'
        end
        return
      end
    end

    render :partial => 'experiment'
  end

  def update_experiment
    view_language

    @experiment = Experiment.find params[:path][0]
    @experiment.language = @view_language

    @container = @experiment.experiment_container

    return render :nothing => true unless @container

    if params[:start]
      @experiment.start! params[:start_time]
    elsif params[:restart]
      @experiment.restart! params[:end_time], :start_time => params[:start_time], :reset => params[:reset]
    elsif params[:stop]
      @experiment.end_experiment! params[:end_time]
    elsif params[:hide]
      @container.update_attribute(:experiment_id, nil) if @experiment.finished?
    else params[:select] && params[:version_id]
      version_id = params[:version_id].to_i
      @experiment.end_experiment! unless @experiment.finished?
      @version = @experiment.versions.find { |v| v.id == version_id }
      PageRevision.activate_page_revision(@experiment.experiment_container, @version.page_revision.id) if @version && @version.page_revision
    end

    p_element_info @container
  end

  protected

  def view_language
    @view_language = params[:language] || Configuration.languages[0]
    @view_language = Configuration.languages[0] unless Configuration.languages.include?(@view_language)
  end

  def element_info_display(node_type,node_id)
    view_language


    if node_type == 'node' 
      node = SiteNode.find(node_id)
      node_func = node.node_type.downcase + '_element_info'
      return self.send(node_func,node)
    elsif node_type == 'mod'
      mod = SiteNodeModifier.find(node_id)
      mod_func = mod.modifier_type.downcase + '_modifier_info'
      return self.send(mod_func,mod)
    end
    render :nothing => true
  end
  
  # Domain Element Information
  def r_element_info(node) 
    @node = node
    render :partial => 'domain_element_info'
  end

  def m_element_info(node)
    render :nothing => true
  end
  
  # Page Element Information
  def p_element_info(node, display=true)
   @languages = Configuration.languages
    @revision_info = node.language_revisions(@languages)
    @active_revision_info = @revision_info.detect { |rev| rev[0] == @view_language }
    @node = node
    
    render :partial => 'page_element_info' if display
  end

  # Group Element Information
  def g_element_info(node)
    @node = node

    @node_options = @node.node_options
    if request.post? && params[:group]
      @node_options = @node.set_node_options(params[:group])
      flash.now[:notice] = 'Updated Group Options'.t
    end

    render :partial => 'group_element_info'
  end
  
  # document (File) Element information
  def d_element_info(node) 
  	@node = node
  	render :partial => 'document_element_info'
  end
  
  # Jump (Redirect) Element Information
  def j_element_info(node) 
    @node = node
    
    if request.post?
      unless @node.redirect_detail.update_attributes(params[:redirect])
        @display_edit_form = true
      end
      expire_site
    end
    
    @available_pages = SiteNode.find(:all, :order => 'node_path', :conditions => ['node_type != "R" AND id != ? ',@node.id]).collect do |page|
      [ page.node_path, page.id ]
    end
    
    @redirect_details = @node.redirect_detail || @node.create_redirect_detail
    render :partial => 'redirect_element_info'
  end
  
  
  
  # Template Modifier Information
  def template_modifier_info(mod)
    @mod = mod
    
    @site_templates = SiteTemplate.find(:all,:order => 'name') || []
    
    @frm = SiteNodeModifier::TemplateModifierOptions.new(params[:mod] || @mod.modifier_data)
    
    if request.post?
      if @frm.valid?
        @mod.modifier_data = @frm.to_h
        @mod.save
        @updated = true
      end
      expire_site
    end
    
    render :partial => 'template_modifier_info'
  end
  
  # Framework Modifier Information
  def framework_modifier_info(mod)
  	@mod = mod
    @node = mod.site_node
    
    @languages = Configuration.languages
    @revision_info = mod.language_revisions(@languages)
    @active_revision_info = @revision_info.detect { |rev| rev[0] == @view_language }
    
  	render :partial => 'framework_modifier_info'
  end
  
  def ssl_modifier_info(mod)
  	@mod = mod
    @node = mod.site_node

  	render :partial => 'ssl_modifier_info'
    
  end
  
  # Lock Modifier Information
  def lock_modifier_info(mod)
    @mod = mod
    
    @lock_options = SiteNodeModifier::LockModifierOptions.new(params[:lock] || @mod.modifier_data)
    @lock_options.options ||= []
    @lock_options.redirect =   @lock_options.redirect.to_i
    
    @user_classes = UserClass.find(:all,:order => 'name',:conditions => ['id != ?',UserClass.client_user_class_id ])
    
    @available_pages = SiteNode.find(:all, :order => 'node_path', :conditions => ['node_type != "R" ']).collect do |page|
      [ page.node_path, page.id.to_s ]
    end
    
    @redirect_page = SiteNode.find_by_id(@lock_options.redirect)
    
    if request.post?
      @mod.modifier_data = @lock_options.to_h
      @mod.attributes = params[:mod]
      @mod.save 
      expire_site
    end
    
    @affected_classes=[]
    @available_classes=[]

    @user_classes.each do |cls|
      if cls.has_role?('access',@mod)
        @affected_classes << cls
      else
        @available_classes << cls
      end
    end
    
    
    
  	render :partial => 'lock_modifier_info'
  end
  
  # Edit Control Information
  def edit_modifier_info(mod)
  	@mod = mod
    
  	render :partial => 'edit_control_modifier_info'
  end
  
  
  def domain_modifier_info(mod)
    @mod = mod
    @domain_options = SiteNodeModifier::DomainModifierOptions.new(params[:domain] || @mod.modifier_data)
    if request.post?
      flash.now[:notice] = 'Updated Domain Options'.t
    
      @mod.modifier_data = @domain_options.to_h
      @mod.save 

      expire_site
    end

        render :partial => 'domain_modifier_info'
  end
  
  public
  
  def update_document_file
  	node_id = params[:node_id]
  	file_id = params[:file_id]
  	
  	@node = SiteNode.find(node_id,:conditions => 'node_type = "D"')
  	@file = DomainFile.find(file_id)
  	
  	if @node && @file
  		@node.update_attribute(:node_data,@file.id)
  		
	end
	
	render :nothing => true
  end
  
end
