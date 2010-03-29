# Copyright (C) 2009 Pascal Rettig.

class Editor::PublicationRenderer < ParagraphRenderer #:nodoc:all

  include ApplicationHelper

  features '/editor/publication_feature'

  paragraph :create
  paragraph :view
  paragraph :edit            
  paragraph :data_output
  paragraph :admin_list
  paragraph :list


  protected
  
  def expire_content(cid)
    cid = cid.id if cid.is_a?(ContentModel)
    DataCache.expire_content("ContentModel",cid.to_s)
  end
  
  
  public 
  

  def create
    publication = paragraph.content_publication
    @options = paragraph_options(:create)
    

    if !editor?
      if request.post? && params['entry_' + publication.id.to_s] && !params['partial_form']
        pc,pc_id = page_connection
  

        entry = publication.content_model.content_model.new()


        publication.update_entry(entry,params['entry_' + publication.id.to_s],renderer_state)
        
        if entry.errors.length == 0 && entry.save
          expire_content(publication.content_model_id)
  
          session['content_model'] ||= {}
          session['content_model'][publication.content_model.table_name] = entry.id
          if publication.update_action_count > 0
            publication.run_triggered_actions(entry,'create',myself)
          end
          
          if @options.redirect_page_url
            return redirect_paragraph @options.redirect_page_url
          else
            paragraph_output = form_feature(publication,{:entry => entry, :publication => publication, :submitted => true, :options => @options})
            return render_paragraph :text => paragraph_output
          end
        end
      else
        if publication.view_action_count > 0
          publication.run_triggered_actions(entry,'view',myself)
        end
      end
    end
    
    require_js('prototype')
    require_js('overlib/overlib')
    require_js('user_application')
    
    content_type = "ContentModel" + publication.content_model_id.to_s
    content_target = "New"
    target_display = "#{paragraph.id}_#{myself.user_class_id}"

    # Only look for cached data if we haven't posted and aren't in the editor
    # TO DO - reactivate caching and expand to whole content / publication controller
    paragraph_output = nil; #DataCache.get_content(content_type,content_target,target_display) if !editor? && !params['entry_' + publication.id.to_s]

    if params['entry_' + publication.id.to_s] || editor? || !paragraph_output
        entry = publication.content_model.content_model.new(params['entry_' + publication.id.to_s]) unless entry
        publication_options = (publication.data || {})
        pub_class = publication_options[:form_class].blank? ? nil : publication_options[:form_class]
      multipart  =   publication.content_publication_fields.detect { |fld| fld.content_model_field.field_type == 'image' || fld.content_model_field.field_type == 'document' }

        paragraph_output = form_feature(publication,{:entry => entry, :multipart => multipart,:publication => publication})

      
        # TO DO - reactivate caching and expand to whole content / publication controller
        #DataCache.put_content(content_type,content_target,target_display,paragraph_output) if !editor? && !request.post?
    end

    render_paragraph :text => paragraph_output
  end
  
  
 
 
  def view
  
   publication = paragraph.content_publication
   
   options = paragraph.data.clone || {}
   
   content_connection,connection_entry_id = page_connection()
   
   # Entry ID Values:
   # [['Use Page Connection'.t,nil ], ['Use page connection or display first'.t,-4],['Display random entry'.t,-1], ['Use referrer, otherwise random'.t,-2], ['Use referrer, otherwise blank'.t,-3]
   
   if options[:entry_id] && options[:entry_id].to_i != 0
    entry_id = options[:entry_id] 
   end
   
   pub_options = publication.options
   entry= nil
    if entry_id && entry_id.to_i != 0
      if entry_id.to_i ==  -1
        entry = publication.get_random_entry(options)
      elsif entry_id.to_i == -2 || entry_id.to_i == -3
        entry = publication.get_field_entry('referrer',myself.referrer,options)
        entry = publication.get_random_entry(options) unless entry || entry_id.to_i == -3
      elsif entry_id.to_i == -4
        entry = publication.get_filtered_entry(connection_entry_id,options) if connection_entry_id
        entry = publication.get_filtered_entry(:first,options) unless entry
      elsif entry_id.to_i == -5 && content_connection && content_connection.to_sym == :entry_id
        fld = publication.content_model.content_model_fields.find_by_id(pub_options.url_field)
        if fld
          options[:conditions] = " `#{publication.content_model.table_name}`.`#{fld.field}` = ? "
          options[:values] = [ connection_entry_id ]
          entry = publication.get_filtered_entry(:first,options)
        end
      else
        entry = publication.get_filtered_entry(entry_id,options)
      end
    elsif content_connection 
      if content_connection.to_sym == :entry_id
        entry = publication.get_filtered_entry(connection_entry_id,options)              
      else content_connection.to_sym == :entry_offset
        options[:offset] = connection_entry_id.to_i - 1
        options[:offset] = 0 if options[:offset] < 0
        connection_offset = options[:offset] + 1
        entry = publication.get_filtered_entry(:first,options)              
      end
    elsif editor?
      entry = publication.get_filtered_entry(:first,options)
    else
      render_paragraph :text => ''
      return
    end

    if paragraph.data[:return_page]
      redirect_node = SiteNode.find_by_id(paragraph.data[:return_page])
      if redirect_node
	      return_page = redirect_node.node_path
      end
    end
    
    return_page = nil unless return_page
    
    if !entry && return_page && !editor?
      redirect_paragraph return_page
      return 
    end
    
    if publication.view_action_count > 0
      publication.run_triggered_actions(entry,'view',myself) 
    end
    
    require_css('gallery')
    
    render_paragraph :text => display_feature(publication,{ :entry => entry, :return_page => return_page, :offset => connection_offset, :publication => publication, :page_href => site_node.node_path, :filter_options => options })
  end


  def edit
   publication = paragraph.content_publication
   content_connection,entry_id = page_connection()
   pub_options = paragraph_options(:edit)
   
   
    if entry_id && entry_id.to_i != 0
      entry = publication.content_model.content_model.find_by_id(entry_id)
    elsif editor?
      entry = publication.content_model.content_model.find(:first)
    elsif pub_options.allow_entry_creation
      entry = publication.content_model.content_model.new()
    else
      render_paragraph :text => ''
      return
    end
     
    return_page = pub_options.return_page_url
      
    if request.post? && params['entry_' + publication.id.to_s]
    
      publication.update_entry(entry,params['entry_' + publication.id.to_s],renderer_state)
      new_entry = entry.id ? false : true
      
      if entry.save
        expire_content(publication.content_model_id)
        if publication.update_action_count > 0
      	  publication.run_triggered_actions(entry,new_entry ? 'create' : 'edit',myself) 
        end
        return redirect_paragraph(return_page) if return_page
      end
    else 
      if publication.view_action_count > 0
        publication.run_triggered_actions(entry,'view',myself) 
      end
    end
      
    require_js('prototype')
    require_js('overlib/overlib')
    require_js('user_application')

    publication_options = (publication.data || {})
    pub_class = publication_options[:form_class].blank? ? nil : publication_options[:form_class]
    multipart  =   publication.content_publication_fields.detect { |fld| fld.content_model_field.field_type == 'image' || fld.content_model_field.field_type == 'document' }

    render_paragraph :text =>   form_feature(publication,{:entry => entry, :multipart => multipart,:publication => publication})

      
                    


  end
  
  
  
  def admin_list
    publication = paragraph.content_publication
    
    options = paragraph.data || {}
    detail_page =  SiteNode.get_node_path(options[:edit_page],'#')
    
    if request.post? && params['delete']
      entry = publication.content_model.content_model.find_by_id(params['delete'])
      if entry
        entry.destroy
        expire_content(publication.content_model_id)
        if publication.update_action_count > 0
    	   publication.run_triggered_actions(entry,'delete',myself) 
        end
      end
    else
      if publication.view_action_count > 0
    	  publication.run_triggered_actions(entry,'view',myself) 
      end
    end
    
  
    entries = publication.get_list_data(params[:page]) #content_model.content_model.find(:all)
  
    render_paragraph :partial => '/editor/publication/list',
                      :locals => { :publication => publication,
                                    :entries => entries,
                                    :detail_page => detail_page }
  end
  
  
  def list
  
    publication = paragraph.content_publication
    if publication.view_action_count > 0
    	publication.run_triggered_actions(entry,'view',myself) 
    end

    options = paragraph.data || {}
    detail_page =  SiteNode.get_node_path(options[:detail_page],'#')

    if request.post? &&  params["filter_#{paragraph.id}"] && !params["clear_filter_#{paragraph.id}"]
      filter_data = DefaultsHashObject.new(params["filter_#{paragraph.id}"])
      searching =  params["filter_#{paragraph.id}"].values.detect { |fld| !fld.blank? }
    else
      filter_data = DefaultsHashObject.new({})
      searching = false
    end

    publication.each_page_connection_input do |filter_name,fld|
      conn_type,conn_id = page_connection(filter_name)
      options[conn_type] = conn_id unless conn_id.blank?
    end

    
    entries = publication.get_list_data(params[:page],options,filter_data.to_hash)
  
    require_css('gallery')
  
    data ={ :detail_page => detail_page, :entries => entries[1], :pages => entries[0], :filter => filter_data, :searching => searching  } 
    render_paragraph :text => list_feature(publication,data) 
#     render_paragraph :partial => '/editor/publication/list',
#                       :locals => { :publication => publication,
#                                     :entries => entries,
#                                     :detail_page => detail_page }
  end
  
  

  
  def data_output
      
    publication = paragraph.content_publication
    if !publication
      render_paragraph :text => 'Reconfigure Data Output'
      return 
      
    end
    if publication && publication.view_action_count > 0
	    publication.run_triggered_actions(entry,'view',myself) 
    end
    
    target_string = publication.content_model_id.to_s
    display_string = publication.id.to_s + '-' + paragraph.site_feature_id.to_s
    feature_output,content_type = DataCache.get_content("ContentModel",target_string,display_string)
    
    if !feature_output
      pub_opts = publication.options

      options = paragraph.data || {}

      entries = publication.get_list_data(nil,options)
      data ={ :entries => entries[1], :pages => entries[0] }
      
      content_type = pub_opts.content_type || 'text'
      feature_output = data_feature(publication.feature_name,publication,data)
      DataCache.put_content("ContentModel",target_string,display_string,[feature_output,content_type])
    end
    data_paragraph :data => feature_output,
                    :type => content_type,
                    :disposition => 'inline'
  end
  
 

end
