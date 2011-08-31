# Copyright (C) 2009 Pascal Rettig.

class ContentController < ModuleController #:nodoc: all


  # This isn't a real module controller, it just acts like one with
  # handlers and stuff
  skip_before_filter :validate_module

  layout 'manage'
  
  permit 'editor_content_configure', :except => [ 'index','custom','view','add_tags_form','remove_tags_form','edit_entry','entry', 'active_table' ]

  permit 'editor_content', :except => 'index'

  before_filter :check_view_permission, :only => [ 'view', 'entry' ]
  before_filter :check_edit_permission, :only => [ 'add_tags_form','remove_tags_form','edit_entry' ]

  cms_admin_paths 'content',
    'Content' => { :action =>'index'}
  
  register_handler :content, :fields, "Content::CoreField"
  register_handler :content, :publication, "Content::CorePublication"
  
  register_handler :content, :feature, "Content::CoreFeature::EmailTargetConnect"
  register_handler :content, :feature, "Content::CoreFeature::FieldFormat"
  register_handler :content, :feature, "Content::CoreFeature::FieldAggregate"
  register_handler :content, :feature, "Content::CoreFeature::KeywordGenerator"
  
  register_handler :trigger, :actions, "Trigger::CoreTrigger"

  register_handler :user_segment, :fields, 'EndUserSegmentField'
  register_handler :user_segment, :fields, 'EndUserActionSegmentField'
  register_handler :user_segment, :fields, 'EndUserCacheSegmentField'
  register_handler :user_segment, :fields, 'EndUserTagSegmentField'
  register_handler :user_segment, :fields, 'UserSubscriptionEntrySegmentField'
  register_handler :user_segment, :fields, 'EndUserTokenSegmentField'
  register_handler :user_segment, :fields, 'DomainLogEntrySegmentField'
  register_handler :user_segment, :fields, "EndUserAddressSegmentField"

  register_handler :structure, :wizard, 'Wizards::SimpleSite'
  register_handler :structure, :wizard, 'Wizards::MembersSetup'

  register_handler :chart, :traffic, 'ContentNode'
  register_handler :chart, :traffic, 'SiteNode'
  register_handler :chart, :traffic, 'DomainLogReferrer'

  def index
    @content_models,@content_actions = CmsController.get_content_models_and_actions

    @content_models = @content_models.select do |model|
      myself.has_content_permission?(model[:permission])
    end

    if myself.has_role?(:editor_content)
      @custom_content_models = ContentModel.find(:all,:conditions => 'show_on_content = 1')

      if !myself.has_role?(:editor_content_configure)
        @custom_content_models = @custom_content_models.select do |mdl|
          if mdl.view_access_control?
            myself.has_role?(:view_access_control,mdl)
          else
            true
          end
        end
      end
    end
    
    cms_page_path [],'Content'
  end

  def custom
    cms_page_info([[ 'Content', url_for(:action => 'index') ] ,'Custom Content'],'content')

    @content_models = ContentModel.find(:all,:order => 'name') if myself.has_role?('editor_content')
  end

  protected

  def check_view_permission
    @content_model = ContentModel.find(params[:path][0])

    if(!myself.has_role?(:editor_content_configure) && @content_model.view_access_control?)
      if !myself.has_role?('view_access_control',@content_model)
        deny_access!
        return
      end
    end
  end

  def check_edit_permission
    @content_model ||= ContentModel.find(params[:path][0])

    if(!myself.has_role?(:editor_content_configure) && @content_model.edit_access_control?)
      if !myself.has_role?('edit_access_control',@content_model)
        deny_access!
        return
      end
    end
  end
  
  def expire_content(cid)
    cid = cid.id if cid.is_a?(ContentModel)
    DataCache.expire_content("ContentModel",cid.to_s)
  end
  
  def get_extra_fields
    @extra_fields = { 
          -1 => 'Edit',
          -2 => 'Delete'
          }
  end

  include ActiveTable::Controller   


  def generate_active_table(reset=false)
      @generated_active_table_columns = [ ActiveTable::IconHeader.new('', :width=>10), 
                  ActiveTable::NumberHeader.new("`#{@content_model.table_name}`.id", :label => 'ID',:width => 40),
                  ActiveTable::IconHeader.new('', :width => 10) ] +
      @content_model.content_model_fields.find_all { |elm| elm.show_main_table? && elm.data_field? }.collect do |fld|
        fld.active_table_header 
      end.compact
      if @content_model.show_tags?
        @generated_active_table_columns << ActiveTable::OptionHeader.new("content_tags.id", :label=> "Tags",
                                                  :options => ContentTag.find_select_options(:all,:conditions => ['content_type = ?',@content_model.content_model.to_s ] ) )
                                                  
      end


      include_tags = @content_model.show_tags? ? 'content_tags' : nil
      active_table_generate(@content_model.table_name + '_table',@content_model.content_model,@generated_active_table_columns,{},reset ? { :content_table => { :clear_search=> 1 } } : params,{ :per_page => 15, :include => include_tags, :order => "`#{@content_model.table_name}`.id DESC" })
  end
  public 

  def active_table
    @content_model = ContentModel.find(params[:path][0])

    active_table_action 'entry' do |act,entry_ids|
      mdl = @content_model.content_model
      case act
        when 'delete'
          mdl.destroy(entry_ids)
        when 'copy':
          mdl.find(entry_ids).each { |entry| entry.clone.save }
        when 'add_tags':
          mdl.find(entry_ids).each { |entry| entry.add_tags(params[:added_tags])}
        when 'remove_tags':
          mdl.find(entry_ids).each { |entry| entry.remove_tags(params[:removed_tags])}
      end
    end
    
    @active_table_output = generate_active_table

    render :partial => 'content_table'
  end
  
  def view
  

      cms_page_info([ [ 'Content', url_for(:action => 'index') ] ] +  (@content_model.show_on_content ? [] : [['Custom Content', url_for(:action => 'custom' ) ]]) + [[ '%s',nil,@content_model.name ]] ,'content')
      
    
    
    @active_table_output = generate_active_table(true)
    
  end
  
  def add_tags_form
      @content_model = ContentModel.find(params[:path][0])
      render :partial => 'add_tags_form'
  end
  
  def remove_tags_form
      @content_model = ContentModel.find(params[:path][0])
      @entries = @content_model.content_model.find(:all,:conditions => [ "`#{@content_model.table_name}`.id IN (?)",params[:entry_ids].to_a ], :include => 'content_tags')
  
      @existing_tags = []
      @entries.each do |entry|
        @existing_tags  += entry.tag_names.split(",").map() { |elm| elm.strip }
      end
      @existing_tags.uniq!
    
      render :partial => 'remove_tags_form'
  end
  

  def configure
    content_id = params[:path][0]
    @content_model = ContentModel.find(content_id)

    cms_page_info([ [ 'Content', url_for(:action => 'index') ] ] +  (@content_model.show_on_content ? [] : [['Custom Content', url_for(:action => 'custom' ) ]]) + [[ '%s', url_for(:action => 'view', :path => content_id), @content_model.name ], 'Configure Content Model' ],'content')
    

    if request.post? && params[:content]
      @content_model.attributes = params[:content]
      if params[:feature]
        feature_args = params[:feature].keys.sort.map { |key| params[:feature][key] }
        @content_model.content_model_features_attributes = feature_args
      else
        @content_model.content_model_features_attributes =  []
      end
      
      if @content_model.save
        @content_model.content_node_type_create if @content_model.create_nodes? && !@content_model.content_type
        
        if(params[:show].is_a?(Hash))
          @content_model.content_model_fields.each do |fld|
            fld.update_attributes(:show_main_table => params[:show][fld.id.to_s] ? true : false)
          end
        end
        flash[:notice] = 'Updated configuration options'
        redirect_to :action => :view, :path => content_id
        
        expire_content(@content_model)
      end
    end

    @available_features = [['--Select a feature to add--','']] + get_handler_options(:content,:feature)
                  
                         
  end
  
  def add_feature
    content_id = params[:path][0]
    @content_model = ContentModel.find(content_id)

    @info = get_handler_info(:content,:feature,params[:feature_handler])
    
    if @info 
      @feature = @content_model.content_model_features.build()
      @feature.feature_handler = @info[:identifier]    
      render :partial => 'content_model_feature', :locals => { :feature => @feature, :idx => params[:index] }
    else
      render :nothing => true
    end  
  end 

  def entry
    content_id = params[:path][0]
    entry_id = params[:path][1]
  
   

    cms_page_info([ [ 'Content', url_for(:action => 'index') ] ] +  (@content_model.show_on_content ? [] : [['Custom Content', url_for(:action => 'custom' ) ]]) + [[ '%s', url_for(:action => 'view', :path => content_id), @content_model.name ], 'View Entry' ],'content')
  
    
    @entry = @content_model.content_model.find_by_id(entry_id)
  end
  
  def edit_entry
    content_id = params[:path][0]
    entry_id = params[:path][1]
  
    @content_model = ContentModel.find(params[:path][0])
    
    @entry = @content_model.content_model.find_by_id(entry_id) || @content_model.content_model.new()

    require_js('cms_form_editor')

    if request.post?
      if params[:commit] 
        if @content_model.update_entry(@entry,params[:entry],myself)
          flash[:notice] = "Saved %s" / @entry.identifier_name
          redirect_to :action => 'view', :path => content_id
          expire_content(@content_model)
          return
        end
      else
        redirect_to :action => 'view', :path => @content_model.id
        return
      end
    end
  
    cms_page_info([ [ 'Content', url_for(:action => 'index') ] ] +  (@content_model.show_on_content ? [] : [['Custom Content', url_for(:action => 'custom' ) ]]) + [[ '%s', url_for(:action => 'view', :path => content_id), @content_model.name ], @entry.id ? 'Edit Entry' : 'Create Entry'],'content')
  end
  
  def new

    @content_model = ContentModel.new(params[:content_model] || { :customized => false })

    cms_page_info([ [ 'Content', url_for(:action => 'index') ] , ['Custom Content', url_for(:action => 'custom' ) ], 'Create a Content Model' ],'content')
    
    
    if request.post? && params[:commit]
      @content_model.customized =  true
      @content_model.model_preset = 'custom'
      if @content_model.save
        # Need to add default fields here
        
        # Run in a worker as migrations don't seem to really be web safe
        # We also muck with db connections, so better to just offload from the
        # web server
        worker_key = MigrationHandlerWorker.async_do_work(
                                                          :content_model_id =>  @content_model.id,
                                                          :domain_id => DomainModel.active_domain_id,
                                                          :action => 'create_table')
        
       results = Workling.return.get(worker_key)
        
        while !results
          sleep(1)
          results = Workling.return.get(worker_key)
        end
        
        expire_content(@content_model)
        if @content_model.customized?
          redirect_to :action => 'edit', :path => @content_model.id, :created => 1
          return
        else
          redirect_to :action => 'view', :path => @content_model.id
          return
        end
      end
    elsif request.post? 
      redirect_to :action => 'custom'
    end
  
  end
  
  def edit
    content_id = params[:path][0]
    @created = params[:created]
  
    @content_model = ContentModel.find(content_id)
  
    cms_page_info([ [ 'Content', url_for(:action => 'index') ] ] +  (@content_model.show_on_content ? [] : [['Custom Content', url_for(:action => 'custom' ) ]]) + [[ '%s', url_for(:action => 'view', :path => content_id), @content_model.name ],'Edit Content Fields' ],'content')
    
    @field_types = ContentModel.content_field_options
    
  end
  
  
  
  def new_field
    @content_field =ContentModelField.new(params[:add_field])
    @content_field.field_options={}
    
    if !@content_field.valid?
      render :inline => "<script>alert('#{jvh("Invalid Field: " + @content_field.errors.full_messages.join(",")) }');</script>"
    else
      render :partial => 'edit_field', :locals => { :fld => @content_field , :field_index => params[:field_index]}
    end
  end
  
  def update_model
    content_id = params[:path][0]
  
  
    @content_model = ContentModel.find(content_id)
    
    @fields, fields_valid = @content_model.process_fields((params[:model_fields]||[]).map { |idx| params[:field][idx] })
    
    if request.post? && fields_valid
       worker_key = MigrationHandlerWorker.async_do_work( :content_model_id =>  @content_model.id,
                                                :domain_id => DomainModel.active_domain_id,
                                                  :fields => @fields.map { |fld| fld.attributes },
                                                  :field_deletions => params[:delete],
                                                  :action => 'update_table'
                                                )
      results = Workling.return.get(worker_key)
      
      while !results
        sleep(1)
        results = Workling.return.get(worker_key)
      end
      expire_content(@content_model)
      
    else
      @fields_errors=true
    end
  end
  
  def destroy
    content_id = params[:path][0]

    @content_model = ContentModel.find(content_id)
    
    cms_page_info([ [ 'Content', url_for(:action => 'index') ] ] +  (@content_model.show_on_content ? [] : [['Custom Content', url_for(:action => 'custom' ) ]]) + [['Really Destroy Content Model: %s',nil,@content_model.name ]],'content')

    
    if request.post? && params[:destroy] == session[:destroy_content_hash]

     logger.warn(params[:destroy])
     logger.warn(session[:destroy_content_hash])
      worker_key =  MigrationHandlerWorker.async_do_work(
                                                         :content_model_id =>  @content_model.id,
                                                         :domain_id => DomainModel.active_domain_id,
                                                         :action => 'destroy_table'
                                                         )
      results = Workling.return.get(worker_key)
      
      while !results
        sleep(1)
        results = Workling.return.get(worker_key)
      end
      
      
      expire_content(content_id)
      model = ContentModel.find_by_id(content_id)
      flash[:notice] = model ?  "Could not delete %s" / @content_model.name : "Deleted %s " / @content_model.name
      redirect_to :action => 'index'
      return
    end

      @destroy_content_hash = session[:destroy_content_hash] = rand(100000000).to_s
      
          
  end
  
  def publish
    content_id = params[:path][0]
    
    @content_model = ContentModel.find(content_id)
    
    cms_page_info([ [ 'Content', url_for(:action => 'index') ] ] +  (@content_model.show_on_content ? [] : [['Custom Content', url_for(:action => 'custom' ) ]]) + [[ '%s', url_for(:action => 'view', :path => content_id), @content_model.name ],'Publish' ],'content')
    
    @publication = @content_model.content_publications.build(params[:publish])
    
    if request.post? && params[:publish]
      @publication.data = { :fields => [] }
      if @publication.save
      
        # Add all the fields by default
        @publication.add_all_fields! if @publication.start_empty.blank?
        expire_content(@content_model)
      
        redirect_to :action => :publication, :path => [ @content_model.id, @publication.id ]
      end
    end
    
    @publication_types = ContentPublication.publication_type_select_options
  end
  
  def publication
    content_id = params[:path][0]
    publication_id = params[:path][1]
    
    @content_model = ContentModel.find(content_id)
    @publication = @content_model.content_publications.find(publication_id)
    
    
    cms_page_info([ [ 'Content', url_for(:action => 'index') ] ] +  (@content_model.show_on_content ? [] : [['Custom Content', url_for(:action => 'custom' ) ]]) + [[ '%s', url_for(:action => 'view', :path => content_id), @content_model.name ],
                    ['Publications', url_for(:action => 'publications', :path => content_id)],
                    ['%s',nil,@publication.name ]],'content')
    
    @publication_options = @publication.options
    
    
    @available_fields = @content_model.content_model_fields.collect { |fld| [ fld.name, fld.id ] }
    @model_fields = [['--Select Field--'.t,'']] + @content_model.content_model_fields.collect { |fld| [ fld.name, fld.id.to_s ] }
    get_extra_fields
    
    if @publication.publication_type == 'admin_list'
      @available_fields += @extra_fields.collect() { |val,fld| [ fld.t, val ] }
    end
    
  end
  
  def delete_publication
    content_id = params[:path][0]
    publication_id = params[:path][1]
    @content_model = ContentModel.find(content_id)
    @publication = @content_model.content_publications.find(publication_id)
  
    @publication.destroy
    
    expire_content(@content_model)
    render :nothing => true
  end
  
  def new_pub_field
    content_id =params[:path][0]
    pub_id =params[:path][1]
    
    @content_model = ContentModel.find(content_id)
    @publication = @content_model.content_publications.find(pub_id)
    
    get_extra_fields
    
    
    if params[:add_field][:field_id].to_i > 0
      @model_field = @content_model.content_model_fields.find(params[:add_field][:field_id])
      @pub_field = @publication.content_publication_fields.build(
					      :label => @model_field.name,
					      :field_type => @publication.field_type_options[0][1],
					      :data => {},
					      :content_model_field_id => @model_field.id
					      )
    elsif @extra_fields[params[:add_field][:field_id].to_i]
      @pub_field = @publication.content_publication_fields.build(
					      :label => @extra_fields[params[:add_field][:field_id].to_i],
					      :field_type => 'value',
					      :data => {},
					      :content_model_field_id => params[:add_field][:field_id].to_i
					      )
    else
      render :nothing => true
      return
    end
    
    
    
    render :partial => 'pub_field', :locals => { :fld => @pub_field, :field_index => params[:field_index], }
  end  
  

  def publications
    content_id = params[:path][0]
    
    
    @content_model = ContentModel.find(content_id)

    cms_page_info([ [ 'Content', url_for(:action => 'index') ] ] +  (@content_model.show_on_content ? [] : [['Custom Content', url_for(:action => 'custom' ) ]]) + [
                    [ '%s', url_for(:action => 'view', :path => content_id), @content_model.name ],
                    'Publications'],'content')
    
    @publications = @content_model.content_publications
  
    
  
  end
  
  def update_publication
    pub_id =params[:path][0]
    
    @publication = ContentPublication.find(pub_id)
    @content_model = @publication.content_model
    
    
   
    @preview = params[:preview].to_i == 1 ? true : false
    
    
     # Need to gather our index and values together so we can update
     # position at the same time
     if params[:pub_fields].is_a?(Array)
	    field_data  = params[:pub_fields].collect do |index|
  	    [ index, params[:field][index.to_s] ]
	    end
     else
	    field_data = []
     end
     # Now we have:
     # [ [ position_1_index, position_1_data ], [ position_2_index, position_2_data ] ... ]

     options = @publication.options(params[:options])
     
    @publication.data = options.to_h
    @publication.attributes = params[:publication]
     @publication.save
     
     expire_content(@content_model)
     publication_fields = @publication.content_publication_fields.index_by(&:id)
     
     @field_ids_update  = []
     
     field_data.each_with_index do |info,position|
      fld_index = info[0]
      fld_data = info[1]
      pub_field= publication_fields[fld_data[:id].to_i] || @publication.content_publication_fields.build()
      pub_field.label = fld_data[:label]
      pub_field.content_model_field_id= fld_data[:content_field_id]
      pub_field.field_type = fld_data[:field_type]
      
      pub_field.position = position

      fld_opts = pub_field.field_options(fld_data)
      fld_opts.valid?

      pub_field.data = fld_opts.to_hash
      
      # Quick hack make sure the preset is in the right format
      # Create a new object of the preset type,
      # and assign the preset value to the field
      # when we get it back out, should be in the correct format
      if fld_data[:preset] && !fld_data[:preset].blank?
        entry = @content_model.content_model.new(pub_field.content_model_field.default_field_name.to_sym => fld_data[:preset])
        pub_field.data[:preset] = entry.send(pub_field.content_model_field.default_field_name.to_sym)
      end
                       
      pub_field.save
      
      @field_ids_update << [ info[0],pub_field.id ]
     end
     
     if params[:delete].is_a?(Array)
      params[:delete].each do |del|
        fld = publication_fields[del.to_i]
        fld.destroy if fld
      end
     end
     
     @publication.content_publication_fields.reload
     
    if @preview
      @content_data = @publication.generate_preview_data
    end
     
  end
  
  def update_triggered_actions
    action = TriggeredAction.find(params[:triggered_action_id])
    action.update_attribute(:comitted,true)
    
    @publication = ContentPublication.find(params[:publication_id])
    @publication.view_action_count = @publication.triggered_actions.count(:conditions => 'action_trigger = "view"')
    @publication.update_action_count = @publication.triggered_actions.count(:conditions => 'action_trigger != "view"')
    @publication.save
    
    expire_content(@content_model)
    render :action => 'update_triggered_actions'
  
  end

  def delete_triggered_action
    action = TriggeredAction.find(params[:triggered_action_id])
    action.destroy

    @publication = ContentPublication.find(params[:publication_id])
    @publication.view_action_count = @publication.triggered_actions.count(:conditions => 'action_trigger = "view"')
    @publication.update_action_count = @publication.triggered_actions.count(:conditions => 'action_trigger != "view"')
    @publication.save
    
    expire_content(@content_model)
    render :action => 'update_triggered_actions'

  end
end
