# Copyright (C) 2009 Pascal Rettig.


class Media::ManageController < ModuleController
  
  permit 'gallery_edit_galleries'
  component_info 'Media'
  
   cms_admin_paths "content",
                   "Content" =>   { :controller => '/content' },
                   "Galleries" =>  { :controller => '/media/manage', :action => 'galleries' }
  
  include ActiveTable::Controller
  active_table :galleries_table, Gallery,
                [ ActiveTable::IconHeader.new('',:width => 10),
                  ActiveTable::StaticHeader.new('Title Image'),
                  ActiveTable::StringHeader.new('galleries.name',:label => 'Name'),
                  ActiveTable::NumberHeader.new('image_count',:label => 'Images') ]
  
  def display_galleries_table(display = true)
    active_table_action('gallery') do |act,gallery_ids|
    case act
      when 'delete':
        Gallery.destroy(gallery_ids)
      end
   end
    
  
    @active_table_output = galleries_table_generate params, :include => :first_image, :order => 'galleries.name'
    
    render :partial => 'galleries_table' if display
  end
  
  def galleries
    cms_page_path ['Content'],'Galleries'
    
    display_galleries_table(false)
  end
  
  def gallery_info
    @gallery = Gallery.find_by_id(params[:path][0]) || Gallery.new
    
    cms_page_path ['Content','Galleries'], @gallery.id  ? [  'Edit %s', nil, @gallery.name ]  : 'Create Gallery'
    if params[:gallery] && params[:gallery][:container_id].present?
      params[:gallery][:container_type] = "SocialUnit"
    end
    if request.post? && params[:gallery] && @gallery.update_attributes(params[:gallery])
      redirect_to :action => 'gallery', :path => @gallery.id
    end
  
  end
  
  def gallery
    @gallery = Gallery.find_by_id(params[:path][0])
    if !@gallery
      redirect_to :action => 'gallery_info'
      return
    end
    
    cms_page_path ['Content','Galleries'], [ '%s',nil,@gallery.name ]
  end
  
  def gallery_upload
      @gallery = Gallery.find(params[:path][0])  
      
      # This will create a gallery image automatically
      file = DomainFile.image_upload(params[:upload],@gallery.domain_file_id)
      if file
        @img =@gallery.gallery_images.find_by_domain_file_id(file.id)
        @upload = true
        render :partial => 'gallery_upload'
      else
        render :nothing => true
      end
  end
  
  def update_image
      @gallery = Gallery.find(params[:path][0])  
      @gal_image = @gallery.gallery_images.find_by_id(params[:image_id])
      case params[:image_action]
        when 'delete':
          @gal_image.destroy if @gal_image
        when 'update':
          @gal_image.update_attribute(:name, params[:name])
      end
        
      render :nothing => true
  end
  
  def update_order 
      @gallery = Gallery.find(params[:path][0])  

      params[:gallery_images].each_with_index do |img,idx|    
        GalleryImage.connection.execute("UPDATE gallery_images SET position=" + GalleryImage.connection.quote(idx+1) + 
                      " WHERE id=" + GalleryImage.connection.quote(img))
      end
      render :nothing => true
  end

end
