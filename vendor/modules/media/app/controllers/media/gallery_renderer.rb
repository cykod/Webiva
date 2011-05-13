# Copyright (C) 2009 Pascal Rettig.

class Media::GalleryRenderer < ParagraphRenderer
   
  features '/media/gallery_feature'

  # Galleries Paragraph Displays a list of galleries with certain conditions
  paragraph :galleries

  # Gallery Paragraph Display a specific gallery, based on the Gallery Number input connection
  paragraph :gallery, :default_connection => :gallery_id
  
  # Private Gallery Display a private gallery (editiable by the owner), based on the Gallery Number input connection
  paragraph :private_gallery, :paragraph_cache => :gallery_hash, :input_connections =>[ [ 'Gallery Number','gallery_id'] ]
  
  def self.galleries_hash(para,usr)
    nil
  end
  
  
  def galleries
      @options = paragraph_options(:galleries)
          
      conditions = {}
      if @options.display_type != 'all' && @options.selected_galleries.is_a?(Array) && @options.selected_galleries..length > 0
        conditions['galleries.id'] = @options.selected_galleries
      end

      conn_type,conn_id = page_connection()
      if(conn_type == :container) 
        conditions.merge!(:container_type => conn_id.class.to_s, :container_id => conn_id.id)
      end

      pages,gallery_list = Gallery.paginate(params[:page],
                                               :order => 'occurred_at DESC',
                                               :conditions => conditions,
                                               :per_page => @options.images_per_page)      
      

      perm_conn_type,perm_conn_id = page_connection(:editor)
      can_edit = myself.has_role?('gallery_create_galleries') || perm_conn_id

      detail_page = SiteNode.find_by_id(@options.detail_page);

      data = { :galleries  => gallery_list, :pages => pages,
               :detail_page => detail_page  ? detail_page.node_path : nil,
               :path => page_path, :can_edit => can_edit }
      
      require_css('redbox')
      require_css('gallery')
      require_js('prototype')
      require_js('effects')
      require_js('builder')
      require_js('redbox')
      require_js('helper/gallery')
      
      render_paragraph :text => galleries_feature(data) 
  end
  
   
  def gallery
    @options = paragraph_options(:gallery)
    gallery_connection,gallery_id = page_connection(:input)
    container_connection,container = page_connection(:container)

    if @options.gallery_id.to_i > 0
      current_gallery = Gallery.find_by_id(@options.gallery_id)
    elsif editor?
      current_gallery = Gallery.find(:first)
    else
      target_name = gallery_id.name if gallery_id.respond_to?(:name)
      
      if gallery_connection == :container
        if gallery_id
          if @options.gallery_category.present?
            current_gallery = Gallery.find(:first,:conditions => ['container_type=? AND container_id=? AND category=?',gallery_id.class.to_s,gallery_id.id,@options.gallery_category])
          else
            current_gallery = Gallery.find(:first,:conditions => ['container_type=? AND container_id=?',gallery_id.class.to_s,gallery_id.id])
          end
          current_gallery = Gallery.create(:container => gallery_id,:category => @options.gallery_category,:name => "#{target_name} #{@options.gallery_category}") if !current_gallery && @options.gallery_create
        end
      else
        if container_connection == :container 
          current_gallery = container ?  Gallery.find_by_id(gallery_id,:conditions => { :container_type => container.class.to_s, :container_id => container.id }) : nil
        else 
          current_gallery = Gallery.find_by_id(gallery_id)
        end
      end
    end
    

    perm_conn_type,perm_conn_id = page_connection(:editor)
    # run page edit information if edit parameter & have 
    if params[:edit]
      if ((current_gallery && (perm_conn_id || myself.has_role?('gallery_edit_galleries'))) || 
          (!current_gallery && (perm_conn_id || myself.has_role?('gallery_create_galleries'))))
        unless current_gallery

          current_gallery = Gallery.new(:container => container)
        end
        edit_gallery(current_gallery)
        return 
      end
    end
    
    
    if current_gallery 
      note = ''

      can_edit = myself.user_profile.has_role?('gallery_upload_to_galleries') || perm_conn_id
      if !can_edit && current_gallery.container
        if  current_gallery.container.respond_to?(:gallery_can_edit)
          can_edit =  current_gallery.container.gallery_can_edit(myself)
        end
      end
      can_upload = can_edit


      if !can_upload &&  current_gallery.container
        if  current_gallery.container.respond_to?(:gallery_can_upload)
          can_upload =  current_gallery.container.gallery_can_upload(myself)
        end
      end


      
      if request.post?
        if params[:gallery_upload]
          if can_upload
            unless current_gallery.domain_file_id
              gallery_folder_id = Configuration.options[:gallery_folder] || 1
              folder = DomainFile.create_folder(current_gallery.name,gallery_folder_id,:automatic => true,:special=>'gallery')
              current_gallery.update_attribute(:domain_file_id,folder.id)
            end
            
            domain_file = DomainFile.image_upload(params[:gallery_upload][:file],current_gallery.domain_file_id)
            if domain_file
              gi = current_gallery.gallery_images.find_by_domain_file_id(domain_file.id)
              gi.update_attributes(:name => params[:gallery_upload][:description],:approved => 1) if gi
              
              current_gallery.resort_images(@options.autosort == 'asc' ? true : false ) if @options.autosort != 'no'
              
              redirect_paragraph page_path + "?page=#{params[:page].to_i+1}"
              return
            end
          end
        elsif params[:image]
          if can_edit
            img = current_gallery.gallery_images.find_by_id(params[:image][:image_id])
            img.update_attributes(:name => params[:image][:description])
            if params[:image][:position] && params[:image][:position].to_i != img.position
              img.insert_at(params[:image][:position])
            end

            current_gallery.resort_images(@options.autosort == 'asc' ? true : false )  if @options.autosort != 'no'
            
            redirect_paragraph page_path + "?page=#{params[:page].to_i}"
            return
          end
        elsif params[:delete_image] && params[:delete_image][:gallery_id].to_i == current_gallery.id
          if can_edit
            img = current_gallery.gallery_images.find_by_id(params[:delete_image][:image_id])
            img.domain_file.destroy if img.domain_file && img
            img.destroy if img

            current_gallery.resort_images(@options.autosort == 'asc' ? true : false )  if @options.autosort != 'no'
            
            redirect_paragraph page_path + "?page=#{params[:page].to_i}"
            return
          end
        end
      end
      
      pages,images = GalleryImage.paginate(params[:page], 
                                            :conditions => { :gallery_id => current_gallery.id },
                                                :per_page => @options.page_size,
                                                :include => :domain_file)
    
    
      data = { :gallery => current_gallery,
              :images => images,
              :pages => pages,
              :page_path => page_path,
              :can_upload => can_upload,
              :can_edit => can_edit
              }
      feature_output = gallery_feature(data) 
      
      if @options.include_javascript
        require_css('redbox')
        require_css('gallery')

        require_js('prototype')
        require_js('effects')
        require_js('builder')
        require_js('redbox')
        require_js('helper/gallery')
      end

      render_paragraph :partial => "/media/gallery/gallery_paragraph", 
                    :locals => { :feature_output => feature_output, 
                                  :can_upload => can_upload, 
                                  :can_edit => can_edit,
                                  :images => current_gallery ? current_gallery.gallery_images.find(:all,:order => 'position',:include => :domain_file) : [],
                                  :gallery => current_gallery,
                                  :editing => self.editor?,
                                  :options => @options }
    else
      data = {  }
      render_paragraph :text => gallery_feature(data) 
    end
    
  end
  
  def self.gallery_hash(para,usr,params = {})
    nil
  end
  
  
  
  def edit_gallery(current_gallery)
    options = paragraph.data

    new_gallery = current_gallery.id ? false : true
    
    if request.post? && params[:gallery]
      
      if current_gallery.update_attributes(params[:gallery])
        # If we have view page to go to,
        # Go there, otherwise just display the save page
          if new_gallery
            unless current_gallery.domain_file_id
              gallery_folder_id = Configuration.options[:gallery_folder] || 1
              folder = DomainFile.create_folder(current_gallery.name,gallery_folder_id,:automatic => true)
              current_gallery.update_attribute(:domain_file_id,folder.id)
            end
            redirect_paragraph page_path + "/" + current_gallery.id.to_s
          else
            redirect_paragraph page_path
          end
          return
      end
    elsif request.post? && params[:delete]
      if current_gallery.id == params[:delete].to_i
        current_gallery.destroy
        options = paragraph.data || {}
        if options[:list_page].to_i > 0
          list_page = SiteNode.find_by_id(options[:list_page].to_i)
          if list_page
            redirect_paragraph list_page.node_path
            return
          end
        end
        render_paragraph :text => 'Deleted Gallery'
        return
      end
    end
  
    require_js('prototype')
    require_js('user_application')
  
    render_paragraph :partial => "/media/gallery/edit_gallery", :locals => { :gallery => current_gallery, :saved_gallery => @saved } 
  end

end
