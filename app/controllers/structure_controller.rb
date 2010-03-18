# Copyright (C) 2009 Pascal Rettig.

class StructureController < CmsController  # :nodoc: all

  public
  
  permit ['editor_structure','editor_structure_advanced'], :except => [ :index, :element_info, :wizards ]
  permit ['editor_website','editor_structure','editor_structure_advanced'], :only => [:index, :element_info]


  permit ['editor_structure_advanced'], :only => [:wizards]

  helper :application
  
  cms_admin_paths 'website'

  
  def index 
    session[:structure_view_modifiers] = @display_modifiers= params[:modifiers] ||
      session[:structure_view_modifiers] || 
      (myself.has_role?('editor_structure_advanced') ? 'show' : 'hide')
    
    session[:structure_view_modules] = @display_modules = params[:modules] ||
      session[:structure_view_modules] ||  'hide'
    
    session[:show_archived] = @show_archived = params[:archived] ||
      session[:show_archived] || 'hide'

    
    if !myself.has_role?('editor_structure_advanced')
      @display_modifiers = session[:structure_view_modifiers] = 'hide'
      @display_modules = session[:structure_view_modules] = 'hide'
    end
    
    
  
    @version = SiteVersion.default
    
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

    cms_page_info 'Website', 'website',myself.has_role?('editor_structure_advanced') ? 'CMSStructure.popup();' : nil
    render :action => 'view', :layout => "manage"
  end


  def wizards
    cms_page_path ['Website'], "Wizards"

    @wizard_list = get_handler_info(:structure,:wizard) if myself.has_role?('editor_structure_advanced')
    @wizard_list ||= []
    @wizard_list = @wizard_list.select { |info| myself.has_role?(info[:permit]) }
 
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
    md = node.add_modifier(modifier_type)
    
    render :partial => 'site_node_modifier', :locals => { :mod => md }
  end
  
  
  def copy_node
  
    parent_id = params[:parent_id]
    node_id = params[:node_id]
    
    @node = SiteNode.find(params[:node_id])
    parent = SiteNode.find(params[:parent_id])
    
    @new_node = @node.duplicate!(parent)
    
    render :partial => 'path', :locals => { :paths => [@new_node] }    
  end
  
  def add_node 
    parent_node = SiteNode.find(params[:parent_id])
    node_type = params[:node_type]  
    title = params[:title] || 'enter_title'
    
    if(node_type == 'M')
      module_name = params[:module_name] 
      
      if SiteModule.site_node_module_active?(module_name)
      
        node = SiteNode.new({ :node_type => node_type,
                              :title => title,
                              :site_version_id => parent_node.site_version_id,
                              :module_name => module_name })
      else
        render :nothing => true
        return 
      end
    else
      node = SiteNode.new({ :node_type => node_type,
                            :site_version_id => parent_node.site_version_id,
                            :title => title })
    end
    
    node.save
    node.move_to_child_of(parent_node)
    
    if node_type == 'P'
      node.page_revisions[0].update_attributes(:created_by => myself)
    end
    
    render :partial => 'path', :locals => { :paths => [node] }
    
  end
  
  def remove_node
    node_id = params[:node_id]
    
    node = SiteNode.find(node_id)
    node.destroy
    
    render :nothing => true
  end
  
  def remove_modifier 
    modifier_id = params[:modifier_id]
    mod = SiteNodeModifier.find(modifier_id)
    mod.destroy
    
    render :nothing => true
  end
  
  def move_modifier
    mod = SiteNodeModifier.find(params[:modifier_id])
    node = SiteNode.find(params[:node_id])
    
    mod.remove_from_list
    mod.position = node.site_node_modifiers.last.position + 1
    node.site_node_modifiers << mod
    mod.move_to_top
    
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
    @revision = PageRevision.find(params[:revision])
    
    @revision.update_attributes(params[:revision_edit])
  
  
    @languages = Configuration.languages
    @node = @revision.revision_container
    @revision_info = @node.language_revisions(@languages)
    
    expire_site

    info = @revision_info.detect { |elm| elm[1] == @revision }
    
    render :partial => 'revision_info', :locals => { :info => [ @revision.language, @revision,info[2]] }
  end
  
  def update_site_node_options
    @node = SiteNode.find(params[:path][0])
    
    node_arr = {}
    [ 'include_in_sitemap','follow_links','cache_page','index_page','archived' ].each do |atr|
      node_arr[atr] = params[:site_node][atr]
    end
    
    expire_site
    
    @node.update_attributes(node_arr)
    
    
    render :partial => 'site_node_options'
  
  end
  
  def create_revision
    revision_id = params[:revision_create][:from_revision_id] if params[:revision_create]
    language = params[:language]
  
    if revision_id
      @revision = PageRevision.find(revision_id)
      @new_revision = @revision.clone
      @new_revision.language = language
      @new_revision.revision_type = 'real'
      @new_revision.active= false
      @new_revision.save
      
      @revision.page_paragraphs.each do |para|
        new_para = para.clone
        new_para.page_revision_id=@new_revision.id
        new_para.save
      end
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
      render :partial => 'revision_info', :locals => { :info => [ @new_revision.language, @new_revision, @new_revision  ] }
    else
      @mod =  @new_revision.revision_container
      @node = @mod.site_node
      @revision_info = @mod.language_revisions(@languages)
      render :partial => 'framework_revision_info', :locals => { :info => [ @new_revision.language, @new_revision,  @new_revision ] }
    end
    
    expire_site
  
  end
  
  
  protected
  def element_info_display(node_type,node_id)
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
  def p_element_info(node)
   @languages = Configuration.languages
    @revision_info = node.language_revisions(@languages)
    @node = node
    
    render :partial => 'page_element_info'
  end

  # Group Element Information
  def g_element_info(node)
    @node = node
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
    
    @redirect_details = @node.redirect_detail
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
