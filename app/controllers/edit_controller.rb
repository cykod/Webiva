# Copyright (C) 2009 Pascal Rettig.

require 'maruku'

# The page editor controller
class EditController < ModuleController # :nodoc: all

  # This isn't a real module controller, it just acts like one
  skip_before_filter :validate_module

  helper :paragraph, :page
  
  include HtmlExtractor
  include SiteNodeEngine::Controller
  
  permit 'editor_editor'

  register_permission_category :paragraph, 'Page Editor', 'Permissions relating to the webiva page editor. Must have the Editor permission to access these permissions.'
  register_permissions :paragraph, [ [:code, 'Code','Use Code Paragraphs' ],
                                     [:textile, 'Textile','Use Textile Paragraphs' ],
                                     [:markdown, 'Markdown','Use Markdown Paragraphs' ],
                                     [:gallery, 'Gallery','Use Gallery Paragraphs' ],
                                     [:navigation, 'Navigation','Use Navigation Paragraphs' ],
                                     [:member, 'Member','Use Member Paragraphs' ],
                                     [:media, 'Media','Use Media Paragraphs' ],
                                     [:action, 'System','Use System Paragraphs' ],
                                     [:module, 'Module Paragraphs','Use any module paragraphs' ],
                                     [:content, 'Publication','Use Publication paragraphs' ]
                                 ]

  register_action '/editor/auth/login', :description => 'User Logged in', :level => 2
  register_action '/editor/auth/logout', :description => 'User Logged Out', :level => 2
  register_action '/editor/auth/cookie', :description => 'User Cookie Login', :level => 2
  register_action '/members/edit', :description => 'Admin account edit', :level => 2
  register_action '/editor/auth/user_registration', :description => 'User Registered'


  private
  
  def get_container
    @container_arg = params[:path][0] == 'page' ? 'page' : 'framework'
    @container_type = params[:path][0] == 'page' ? 'site_node' : 'site_node_modifier'
    @container_id = params[:path][1]
    @container_cls = @container_type.camelcase.constantize
  end
  
  def create_temporary_revision(page,revision_id)
    temp_revision = page.create_temporary_revision(revision_id)
    temp_revision.created_by = myself
    temp_revision.save
    temp_revision
  end
  
  def save_temporary_revision(revision) 
    revision.updated_by = myself
    revision.make_real()
  end
  
  def save_temporary_revision_as(revision,version,name=nil)
    revision.updated_by = myself
    revision.make_new_version(version, name)
  end
  
  
  def edit_page_info(container_type,container_id,passed_revision_id=nil,real_revision=false)
    cls = container_type.camelcase.constantize
    
    @page = cls.find_page(container_id)
    
    raise ActiveRecord::RecordNotFound.new("Page Not Found") unless @page

    if container_type == 'site_node'
      @site_node = @page
    else
      @site_node = @page.site_node
    end
    
    # Give an imaginary full path for the editor
    params[:full_path] = @site_node.node_path.split("/")
    
    
    if real_revision
      passed_revision_id=nil if passed_revision_id.is_a?(String) && passed_revision_id.empty?
      if passed_revision_id 
        if passed_revision_id.to_i > 0
          @real_revision =@page.page_revisions.find(passed_revision_id)
          page_revision_id=@real_revision.id
        else
          conditions = { :revision_type => 'real' }
          conditions[:revision] = params[:version] if params[:version] 
          @real_revision = @page.page_revisions.find(:first,:conditions => conditions,
                                              :order => "language=#{Configuration.connection.quote(passed_revision_id)} DESC, active DESC, revision DESC, id DESC")
          page_revision_id = @real_revision.id
        end
      else
        rev = @page.page_revisions.find(:first,
                    :conditions => 'revision_type = "real"',
                    :order => "language=#{Configuration.connection.quote(Configuration.languages[0])} DESC, active DESC, revision DESC, id DESC")
        @real_revision = rev
        page_revision_id = rev.id 
                        
      end
      
      raise "Invalid Page: #{page_id}" unless @page
      
      @temp_revision = create_temporary_revision(@page,page_revision_id)
      
      # Save the paragraph updates 
      revision_id = @temp_revision.id
    else
      revision_id = passed_revision_id
    end
    @node_engine = SiteNodeEngine.new(@page,:edit => @temp_revision ? @temp_revision : revision_id)
    
    @output = @node_engine.run(self,myself)

    @site_template = SiteTemplate.find(@output.css_site_template_id)
    @revision = @output.revision
    # If we were creating a new temporary revision, get rid of any old ones
    if real_revision
      @real_revision.cleanup_temporary
    end
    
  end
  
  def get_site_pages(page,current_template_id=0)

    page_list = []
    page.site_node_modifiers.each do |mod|
      if mod.modifier_type == 'template'
        if mod.modifier_data && mod.modifier_data[:template_id]
          current_template = SiteTemplate.find_by_id(mod.modifier_data[:template_id],:select => 'id,parent_id')
          current_template_id = current_template.parent_id || mod.modifier_data[:template_id] if current_template
        end 
      elsif mod.modifier_type == 'page' && page.node_type == 'P'
        page_list << [ page, current_template_id ]
      elsif mod.modifier_type == 'framework'
        page_list << [ mod, current_template_id ]
      end
    end
    page.child_cache.each do |pg|
      page_list += get_site_pages(pg,current_template_id)
    end
    page_list

  end
  
 def sort_paragraphs(zone_info)
    if zone_info.is_a?(Hash)
      zone_info.each do |zone_idx, para_ids|
        zone = SiteTemplateZone.find(:first,:conditions => ['site_template_id=? AND position=?', @output.site_template_id, zone_idx])

        if(zone) 
          para_ids.each_with_index do |paragraph_id,paragraph_idx|
            paragraph = @revision.page_paragraphs.find_by_id(paragraph_id);
            paragraph.update_attributes(:position => paragraph_idx + 1,
                                        :zone_idx => zone_idx) if paragraph
          end
        end

      end
    end
    
    # clear and lock paragraphs aren't included in ordering
    # @revision.page_paragraphs.find(:all,:conditions => 'display_type IN ("clear","lock")').each do |para|
    #  para.move_to_top
    # end
  end  
  
  def update_paragraphs(paragraphs)
    paragraphs.each do |para_id,para_data|
      para = @revision.page_paragraphs.find_by_id(para_id)
      para.update_attributes(:display_body => para_data)
    end
  
  end
  
  def save_changes_helper(is_real=true)
    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],false)
  
    sort_paragraphs(params[:zone] || {})
    update_paragraphs(params[:paragraph] || {})
    
    
    if(is_real)
      @revision.page_paragraphs.reload
      save_temporary_revision(@revision)
    
      if @revision.active?
        expire_site
      end
    end
  end
  
  def generate_paragraph_types
    @paragraph_types = [ ['hidden', 'lock','Zone Lock',nil,[]],
                         ['hidden', 'clear','Zone Clear',nil,[]],
                         ['builtin', 'html','Basic Paragraph',nil,[]]
                        ]
    @available_paragraph_types = @paragraph_types.clone
    @available_paragraph_types += [ ['builtin', 'code', 'Code Paragraph',nil,[]],
                                    ['builtin', 'markdown', 'Markdown Paragraph',nil,[]],
                                    ['builtin', 'textile', 'Textile Paragraph',nil,[]] ]
    @paragraph_types << @available_paragraph_types[-3] if myself.has_role?('paragraph_code')
    @paragraph_types << @available_paragraph_types[-2] if myself.has_role?('paragraph_textile')
    @paragraph_types << @available_paragraph_types[-1] if myself.has_role?('paragraph_markdown')

    editor_paragraph_types = ParagraphController.get_editor_paragraphs
    editor_paragraph_types.sort! { |elm1,elm2| elm1[0] <=> elm2[0] }
    editor_paragraph_types.each { |elm| elm[2].sort! { |a,b| a[2] <=> b[2] } }

    last_type = nil
    editor_paragraph_types.each do |type|
      @available_paragraph_types += type[2]
      
      if !type[1] || myself.has_role?(type[1].to_s)
        @paragraph_types << type[0] if(last_type != type[0])
        @paragraph_types += type[2]
        last_type = type[0]
      end
    end

    module_paragraphs =  SiteModule.get_module_paragraphs
    last_type = nil
    module_paragraphs.to_a.sort{ |a,b| a[0] <=> b[0] }.each do |type|
      type = type[1]
      paras = type[2].sort { |a,b| a[2] <=> b[2] }
      @available_paragraph_types += paras
      
      if myself.has_role?('paragraph_module') && (!type[1] || myself.has_role?(type[1].to_s))
        @paragraph_types << type[0] if(last_type != type[0])
        @paragraph_types += paras
        last_type = type[0]
      end
    end
    
    content_paragraphs = ContentPublication.get_publication_paragraphs
    @available_paragraph_types += content_paragraphs 
    @paragraph_types +=  content_paragraphs  if myself.has_role?('paragraph_content')

    @paragraph_hash = {}
    @available_paragraph_types.each do |para| 
      if para.is_a?(Array) && para.length == 2
        nil
      elsif para.is_a?(Array) && !para[5] 
        @paragraph_hash["#{para[3]}_#{para[1]}"] = para 
      else
        @paragraph_hash["#{para[3]}_#{para[1]}_#{para[5]}" ] = para 
      end
    end
  end
  
  def get_site_features
    SiteFeature.feature_type_hash
  end
  
  public

  def page

    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],true)
    
    @design_styles = SiteTemplate.css_design_styles(@output.css_site_template_id,@revision.language)


    generate_paragraph_types

    # If we're coming from something like a blog post,
    # let us go right back to the correctly permalinked
    # location
    if params[:return_to_site] && session[:return_to_site]
      if session[:return_to_site].include?(@page.node_path)
       @goto_page_override_url = session[:return_to_site]
      end
    end



    @version = @site_node.site_version
    
    @site_root = @version.nested_pages()
    
    @pages = get_site_pages(@site_root)
    
    @available_features = get_site_features
    
    render :layout => false
  end 
  
  def reload_page
    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],true)
    generate_paragraph_types
  
    render :action => 'reload_page'
    # force a javscript content type if we're updating
    headers['Content-Type'] = 'text/javascript; charset=utf-8'
  end
  

  def refresh_info
    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],false)
    generate_paragraph_types
    
    @available_features = get_site_features
    
    render :action => 'refresh_info'
  end
  

  def set_paragraph_feature
    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],false)
    
    generate_paragraph_types
    
    para_index = params[:para_index]
    feature_id = params[:feature_id].to_i
    paragraph_id = params[:paragraph_id]
    
    para = @revision.page_paragraphs.find(paragraph_id)
    
    tpl = SiteTemplate.find(@output.css_site_template_id)
    
    
    if feature_id == 0
      feature_id=nil
    else
      feature = SiteFeature.find_by_id(feature_id)
    end
    
    if !feature_id || feature 
      para.update_attribute(:site_feature_id,feature_id)
    end
    
    render :partial => 'paragraph', :locals => { :para_index => para_index, :para => para }
  
  end
  
  def goto
    get_container
    @site_node = @container_cls.find_page(@container_id)
    @page_revision = @site_node.page_revisions.find(params[:path][2])
    @page_revision.update_attribute(:identifier_hash, PageRevision.generate_hash) unless @page_revision.identifier_hash
    @url = params[:url] || @site_node.node_path
    @url += "?__VER__=#{@page_revision.identifier_hash}" if @site_node.is_a?(SiteNode)
    @url = Configuration.domain_link @url
    redirect_to @url
  end

  def add_paragraph 
    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],false)
    generate_paragraph_types
    
    para_index = params[:para_index]

    options = { :zone_idx => params[:zone], 
                :display_type => params[:display_type],
                :display_module => params[:display_module] || nil,
                :content_publication_id => params[:pub_id] || nil }
    
    @paragraph = PageParagraph.new(options)
    
    @paragraph.page_revision = @revision

    if @paragraph.content_publication
      @paragraph.site_feature = @paragraph.content_publication.primary_feature
    end

    if @paragraph.save
      render :partial => 'paragraph', :locals => { :para => @paragraph, :para_index => para_index }
    end

  end
  
  
  def save_changes
    save_changes_helper
    generate_paragraph_types
    
    @old_revision=@revision
    get_container
    edit_page_info(@container_type,@container_id,
                    @revision.id,
                    true)
    
    render :action => 'save_changes'
  end
  
  def save_changes_and_reload
    save_changes_helper
    generate_paragraph_types
    
    edit_page_info(params[:new_page_type] == 'page' ? 'site_node' : 'site_node_modifier',
                   params[:new_page_id],params[:new_revision_id],true)
  
    render :action => 'reload_page'
  end
  
  
  def save_as
    generate_paragraph_types
    
    version = params[:version]
    version_name = params[:name]

    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],false)
  
    sort_paragraphs(params[:zone] || {})
    update_paragraphs(params[:paragraph] || {})
    
    save_temporary_revision_as(@revision,version,version_name)
    @old_revision=@revision
    
    edit_page_info(params[:path][0] == 'page' ? 'site_node' : 'site_node_modifier',
                   params[:path][1],
                   @revision.id,true)
  
    @save_as = true
    render :action => 'save_changes'
  end

  def preview
    save_changes_helper(false)
    get_container

    render :update do |page|
      page << "$('cms_saving_icon').style.visibility='hidden';"
      page << "cmsEdit.openPreviewWindow();"
    end
  end
  
  def change_version
    get_container
    @version = params[:version]
    @site_node = @container_cls.find_page(@container_id)
    @page_revision = @site_node.page_revisions.find(params[:path][2])
    render :partial => 'change_version'
  end
  
  def backup_changes
    raise 'NotOk'
  end
  
  def delete_paragraph
    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],false)
    
    para = @revision.page_paragraphs.find_by_id(params[:paragraph_id])
    para.destroy if para
    
    render :nothing => true
  end
  
  def modification_history
    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],false)
    
    @page = @container_cls.find(@container_id)
    revision_id = params[:path][2]
    @revision = @page.page_revisions.find(revision_id)
    
    @revisions = @page.page_revisions.find(:all,:conditions => ['revision = ? AND language=? AND revision_type != "temp"',@revision.revision,@revision.language],
                             :order => 'id  DESC')
                             
    render :action => 'modification_history', :layout => false                            
  end
  
  
  def version_history
    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],false)
    
    @page = @container_cls.find(@container_id)
    @revision = @page.page_revisions.find(params[:path][2])
    @version_page = (params[:page] || 0).to_i
    
    count_per_page = 16
    
    conditions = 'revision_type = "real"'
                             
    
    @version_pages = (@page.page_revisions.count(conditions).to_f / count_per_page).ceil
    
    @version_page = (@version_pages - 1)  if @version_page >= @version_pages
    
    @revisions = @page.page_revisions.find(:all,
                            :conditions => conditions,
                            :limit => count_per_page,
                            :offset => @version_page * count_per_page,
                            :order => 'revision DESC, language')
                             
    render :action => 'version_history', :layout => false                           
  end
  
  def activate_version
    get_container
    @page = @container_cls.find(@container_id)
    
    @revision = @page.page_revisions.find(params[:path][2])
    @revision.activate
    @revision.reload
    
    expire_site
    
    render :action => 'version_reload', :layout => false
  end
  
  def deactivate_version
    get_container
    
    @page = @container_cls.find(@container_id)
    @revision = @page.page_revisions.find(params[:path][2])
    @revision.deactivate
    @revision.reload
    
    expire_site
    
    render :action => 'version_reload', :layout => false
  end

  def edit_code
    get_container
    
    require_js('edit_area/edit_area_loader')
    
    @page = @container_cls.find(@container_id)
    @revision = @page.page_revisions.find(params[:path][2])
    
    @paragraph = @revision.page_paragraphs.find(params[:paragraph_id])
    @para_index = params[:para_index]
    
    @body = params[:code]

    @action_url = url_for(:action=>'update_code', :path => params[:path])

    @title = "Edit %s Paragraph" / @paragraph.display_type.humanize
    
    render :action => 'edit_code', :layout => 'manage_window'
  end

  def update_code
    get_container

    @page = @container_cls.find(@container_id)
    @revision = @page.page_revisions.find(params[:path][2])
    
    @paragraph = @revision.page_paragraphs.find(params[:paragraph_id])
    @paragraph.attributes = params[:paragraph].slice(:display_body)

    @errors = @paragraph.validate_markup
    
    if @errors.length == 0 || params[:skip_validation]
      @paragraph.save
      @errors=nil
    end

    @para_index = params[:para_index]
    render :action => 'update_code'
  end
  
  def page_info
    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],false)
  
    render :partial => 'page_info'
  end
  
  
  def update_info
    get_container
    
    @page = @container_cls.find(@container_id)
    @revision = @page.page_revisions.find(params[:path][2])
    
    @revision.update_attributes(params[:revision])
    
    render :action => 'page_info_update'
  end
  
  def page_variables
    get_container
    # output the page, go through each block, and get the variables
    edit_page_info(@container_type,@container_id,params[:path][2],false)
    
    @options = DefaultsHashObject.new(@revision.variables || {})

    @variables = @site_template.options[:options]
    
    render :partial => 'page_variables'
  end
  
  def update_page_variables
    save_changes_helper(false)
    if params[:options].is_a?(Hash)
      opts = {}
      params[:options].each do |key,val|
        opts[key] = val unless val.blank?
      end
    end
    @revision.update_attribute(:variables,opts)
  
    # Recreate the page output
    edit_page_info(@container_type,@container_id,params[:path][2],false)
  
    generate_paragraph_types
    render :action => 'reload_page'
  end


  def page_connections
    get_container
    @page = @container_cls.find(@container_id)
    @revision = @page.page_revisions.find(params[:path][2])
    
    @paragraphs = @revision.full_page_paragraphs # include paras 
    
#    if @page.is_a?(SiteNode) || true
    @outputs = {
      :integer => [
                   [ 0, 'URL', :page_arg_0, 'Page Argument #1 - ' + @page.node_path+ "/XXX", :integer ], 
                   [ 0, 'URL', :page_arg_1, 'Page Argument #2 - ' + @page.node_path + "/xxx/YYY", :integer ],
                   [ 0, 'URL', :page_arg_2, 'Page Argument #3 - ' + @page.node_path + "/xxx/yyy/ZZZ", :integer ] 
                   ],
      :path => [
                [ 0, 'Page', :page_arg_0, "Argument #1 - " + @page.node_path + "/XXX", :path ], 
                [ 0, 'Page', :page_arg_1, "Argument #2 - " + @page.node_path + "/xxx/YYY", :path ],  
                [ 0, 'Page', :page_arg_2, "Argument #3 - " + @page.node_path + "/xxx/yyy/ZZZ", :path ]

              ],
      :title => [ [  0, 'Page Title Full', :title, 'Page Title', :title ]],
      :title_str => [ [  0, 'Page Title String', :title_str, 'Page Title', :title_str ]],
      :user => [ [ 0, 'User ID', :user_id, 'User ID', :user ] ],
      :target => [ [ 0, 'Active User', :user_target, 'User', :target ] ],                   
      :user_target => [ [ 0, 'Active User Target', :user_target, 'User', :user_target ] ],                   
      :user_class => [ [0, 'User Profile', :user_class_id, 'User Profile', :user_class ] ]
                 }
#    else
#      @outputs = {}
#    end
    @inputs = []
    # Build the list of available outputs
    @paragraphs.each do |para|
      if para.content_publication
        para_info = para.editor_info
        
        info = para.content_publication.page_connections

        # Map all the available outputs
        if info[:outputs]
          info[:outputs].each do |pout|
            @outputs[pout[2]] ||= []
            @outputs[pout[2]] << [ para.identity_hash || para.id.to_s, para_info[:name]] + pout
          end
        end

        # But only those inputs for the current page
        if info[:inputs] && para.page_revision_id == @revision.id
          selected_input = (para.connections||{})[:inputs] || {}
          info[:inputs].each do |key,input|

            # paragraph id | other paragraph argument | my argument
            selected_value = selected_input[key.to_sym].map(&:to_s).join("|") if  selected_input[key.to_sym]
            @inputs << { :paragraph_id =>  para.identity_hash || para.id.to_s, 
                         :input_name => key.to_s.humanize,
                         :input_key => key,                         
                         :info => para_info,
                         :input => input,
                         :selected => selected_value }
          end
        end
      end
      if para.display_module
        info = para.editor_info
        
        if info[:outputs]
          info[:outputs].each do |pout|
            output_name = para.page_revision_id == @revision.id ? info[:name] : "(#{para.page_revision.node_path}) #{info[:name]}"
            @outputs[pout[2]] ||= []
            @outputs[pout[2]] << [para.identity_hash || para.id.to_s, output_name] + pout
          end
        end 
       

        if info[:inputs] && para.page_revision_id == @revision.id
          if info[:inputs].is_a?(Array)
            selected = (para.connections||{})[:inputs] || {}
            selected_value = selected[:input].map(&:to_s).join("|") if  selected[:input]

            @inputs << { :paragraph_id =>  para.identity_hash || para.id.to_s, 
              :input_name => 'Input',
              :input_key => 'input',
              :info => info,
              :input => info[:inputs], 
              :selected => selected_value }
          elsif info[:inputs].is_a?(Hash)
            selected_input = (para.connections||{})[:inputs] || {}
            
            info[:inputs].each do |key,input|
              selected_value = selected_input[key.to_sym].map(&:to_s).join("|") if  selected_input[key.to_sym]
              @inputs << { :paragraph_id =>  para.identity_hash || para.id.to_s, 
                :input_name => key.to_s.humanize,
                :input_key => key,                         
                :info => info,
                :input => input,
                :selected => selected_value }
            end
          end
        end
      end
    end
    
    render :partial => 'page_connections'
    
  end


  def update_page_connections
  
    # if the page doesn't have any inputs,
    # Then we have nothing to do
    unless params[:inputs]
      render :nothing => true
      return
    end
    
    get_container
    @page = @container_cls.find(@container_id)
    @revision = @page.page_revisions.find(params[:path][2])
    
    @paragraphs = @revision.page_paragraphs.index_by { |para| para.identity_hash || para.id.to_s }
    
    # Reset the page connections
    @paragraphs.each do |id,para|
      if para.display_module
        para.connections = {}
      end
    end
    
    params[:inputs].each do |paragraph_id,inputs|
      para = @paragraphs[paragraph_id.to_s]
      if para
         inputs.each do |input_key,input_value|
           para.connections[:inputs] ||= {}
           if input_value =~ /^([^|]+)\|([^|]+)\|(.*)$/
            para.connections[:inputs][input_key.to_sym] = [ $1, $2.to_sym, $3.to_sym ]
            if $1.to_i > 0
              output_para = @paragraphs[$1]
              if output_para
                output_para.connections[:outputs] ||= []
                output_para.connections[:outputs] <<  [ $2.to_sym, para.identity_hash, input_key ]
              end
            end
           end
         end
      end
    
    end
      
    @paragraphs.each do |id,para|
      if para.display_module
        para.save
      end
    end
    
    render :nothing => true
  end

  def create_translation
    generate_paragraph_types
    
    get_container
    
    @page = @container_cls.find(@container_id)
    @revision = @page.page_revisions.find(params[:path][2]) 
    
    @language = params[:language]
    @available_revisions = @page.page_revisions.find(:all,:conditions => 'revision_type="real"',:order => 'revision DESC,language')
    
    @available_revisions.each do |rev|
      @current_revision = rev.id  if rev.language == @revision.language && rev.revision == @revision.revision
    end
    
    @translation = DefaultsHashObject.new(
        :trans => 'copy',
        :page_id => @page.id,
        :revision => @revision.revision,
        :revision_identifier => @revision.identifier,
        :language => @language         
        )

    render :partial => 'create_translation'
  end
  
  
  def build_translation
    generate_paragraph_types
    
    get_container
    
    @page = @container_cls.find(@container_id)
    
    revision_identifier = params[:translation][:revision_identifier].split("_")
    @revision = @page.page_revisions.find(:first,:conditions => ['revision_type="real" AND revision=? AND language=?',revision_identifier[0],revision_identifier[1]])
    @new_revision = @revision.clone
    @new_revision.revision = params[:translation][:revision]
    @new_revision.language = params[:translation][:language]
    @new_revision.revision_type = 'real'
    @new_revision.active= false
    @new_revision.save
    
    if(params[:translation][:trans] == 'copy')
      @revision.page_paragraphs.each do |para|
        new_para = para.clone
        new_para.page_revision_id=@new_revision.id
        new_para.save
      end
    end
    
    
    edit_page_info(@container_type,@page.id,@new_revision.id,true)
  
    render :action => 'reload_page'
  end
  
  def save_changes_and_build_translation
      save_changes_helper
      
      build_translation
  end
  
  def delete_ask  
    get_container
    
    @page = @container_cls.find(@container_id)
    @revision = @page.page_revisions.find(params[:path][2])
    @parent_revision = @revision.parent_revision
    
    @delete_type = params[:delete_type]
    @invalid = false
    
    raise 'BadDeleteType' unless %w[edit revision version].include?(@delete_type)
    
    if @delete_type == 'edit'
      cnt = @page.page_revisions.count(:all,:conditions => ['revision_type in ("real","old") AND language=? AND revision=? AND id != ?',@revision.language,@revision.revision,@parent_revision.id])
      @delete_type = 'revision' if cnt == 0
    end 
    
    if @delete_type == 'revision'
      cnt =@page.page_revisions.count(:all,:conditions => ['revision_type="real" AND  id !=  ?',@parent_revision.id])
      @delete_type = 'version' if cnt == 0
    end
    
    if @delete_type == 'version'
      cnt =@page.page_revisions.count(:all,:conditions => ['revision_type="real" AND revision != ? ',@revision.revision])
      @invalid = true if cnt == 0
    end
    
    render :partial => 'delete_ask'
  end
  
  def delete
    generate_paragraph_types
  
    @delete_type = params[:delete_type]
    
    get_container
    
    @page = @container_cls.find(@container_id)
    @revision = @page.page_revisions.find(params[:path][2])
    @parent_revision = @revision.parent_revision
  
    case @delete_type
    when 'edit':
      @replacement_revision =  @page.page_revisions.find(:first,
                                  :conditions => ['revision_type IN("real","old") AND language=? AND  revision=? AND id !=?',
                                                  @revision.language,@revision.revision,@parent_revision.id ],
                                  :order => 'id DESC' )
      @replacement_revision.update_attribute(:revision_type,'real') if @replacement_revision.revision_type == 'old'
      # Get rid of the real revision
      @revision.parent_revision.destroy
      # Get rid of the temporary revision
      @revision.destroy
      
      expire_site if @revision.active?
    when 'revision':
    
    
      @replacement_revision = @page.page_revisions.find(:first,
                                                        :conditions => ['revision_type="real" AND (language != ? OR revision != ? OR id != ?)',@revision.language,@revision.revision,@parent_revision.id],
                                                       :order => "language=#{PageRevision.connection.quote(@revision.language)} DESC, revision DESC")
      # Get rid of all edits with this revision nubmer and the same language
      active = false
      @page.page_revisions.find(:all,:conditions => ['language=? AND revision=?',@revision.language,@revision.revision]).each do |rev|
        rev.destroy
        active = true if rev.active?
      end
      
      expire_site if active
    when 'version'
      @replacement_revision = @page.page_revisions.find(:first,
                                                       :conditions => ['revision_type="real" AND revision != ?',@revision.revision],
                                                       :order => "language=#{PageRevision.connection.quote(@revision.language)} DESC, revision DESC")
      # Get rid of all edits with this revision nubmer and the same language
      active = false
      @page.page_revisions.find(:all,:conditions => ['revision=?',@revision.revision]).each do |rev|
        rev.destroy
        active = true if rev.active?
      end
      
      expire_site if active
    end
    
    edit_page_info(@container_type,@page.id,@replacement_revision.id,true)
    render :action => 'reload_page'
  end

  # Old Fucntions
  
  def translate_text
    verify_domain_page
    
    
    # From the revision
    # Get all the paragraphs
    paragraphs = @revision.page_paragraphs
    
    # Create a list of text strings
    @text = []
    
    if request.post?
      # For each of the html paragraphs
      i=0
      regexp_list = []
      translations =params[:trans][:trans].length 
      while(i < translations)
        if(params[:trans][:trans][i] && params[:trans][:trans][i].strip != '')
          regexp_list << [Regexp.new(Regexp.escape(params[:trans][:text][i])), params[:trans][:trans][i] ]
        end
        i+=1
      end
      
      paragraphs.each do |para|
        if para.display_type == 'html'
          body = para.display_body
          regexp_list.each do |reg|
            body.gsub!(reg[0],reg[1])
          end
          para.display_body = body
          para.save
        end
      end
      
      render :action => 'translate_done'
      return
    else
      # For each of the html paragraphs
      paragraphs.each do |para|
        if para.display_type == 'html'
          @text = @text + html_extract_text(para.display_body)
        end
      end
    end
    @text.uniq!
    
    
    render :action => 'translate_text', :layout => 'manage_window'
  
  end
  
  def update_triggered_actions
    action = TriggeredAction.find(params[:triggered_action_id])
    action.update_attribute(:comitted,true)
    
    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],false)

    @paragraph = action.trigger
    @paragraph.view_action_count = @paragraph .triggered_actions.count(:all,:conditions => 'action_trigger = "view"')
    @paragraph.update_action_count = @paragraph .triggered_actions.count(:all,:conditions => 'action_trigger != "view"')
    @paragraph.save

    
    render :action => 'update_triggered_actions'
  
  end

  def delete_triggered_action
    action = TriggeredAction.find(params[:triggered_action_id])
    action.destroy

    get_container
    edit_page_info(@container_type,@container_id,params[:path][2],false)

    @paragraph = action.trigger
    @paragraph.view_action_count = @paragraph .triggered_actions.count(:all,:conditions => 'action_trigger = "view"')
    @paragraph.update_action_count = @paragraph .triggered_actions.count(:all,:conditions => 'action_trigger != "view"')
    @paragraph.save

    
    render :action => 'update_triggered_actions'

  end


  def link

    render :action => 'link', :layout => 'manage_mce'
  end

  def links
    @links = SiteNode.find(:all,:conditions => 'node_type != "R"',:order => 'node_path')

    render :partial => 'links'
  end

 
end

