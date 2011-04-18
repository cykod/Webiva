# Copyright (C) 2009 Pascal Rettig.

require 'mime/types' 

class FileController < CmsController # :nodoc: all

  permit "editor_files", :except => [:export_status, :export_file]

  layout "manage"
  
  before_filter :calculate_image_size


  cms_admin_paths 'files', 
    'Files' => { :action => 'index' }

  protected  

  def calculate_image_size
    @icon_size = (params[:icon_size]||64).to_i
    
    @image_sizes = DomainFile.image_sizes
    @image_sizes.each do |sz|
      @image_size = sz[0]
      break if sz[1] >= @icon_size
    end
    
    @thumb_size = params[:thumb_size] || 'icon'
    @field = params[:field] || ''
    @select = params[:select] || 'img'
    
    @popup = params[:popup]

    @mce = params[:mce]

    @page = params[:page]
    
    @order = params[:order] || 'name'
   @order_options = [ ['Name >','name'],
                       ['Name <','name_desc'],
                       ['Created Date >','created_at' ],
                       ['Created Date <','created_at_desc'],
                       ['Size >','file_size' ],
                       ['Size <','file_size_desc'],
                       ['Extension >','extension' ],
                       ['Extension <','extension_desc'],
                     ].map { |t| [ t[0].t, t[1] ] }
  end

  public

  def index
    cms_page_path [], "Files"
    
    folder_id = params[:path][0] if params[:path]
    
    @root_folder = DomainFile.root_folder
    
    if folder_id && folder_id.to_i > 0
      @folder = DomainFile.find(folder_id)
      if @folder.file_type != 'fld'
        @folder = @folder.parent
      end  
    end
    
    @folder = @root_folder unless @folder
    
    @selectedFolder = @folder.id
    
    @select = 'all'
    @full_page = true
    @onload = 'FileEditor.init();'

    @page = params[:page] || 1
    
    require_js('edit_area/edit_area_loader')
  end
  
  def load_folder
    @callback = params[:callback] || 'SCMS.setFileField'
  
    folder_id = params[:path][0]
    @folder = DomainFile.find_folder(folder_id)
    
    if(params[:file_id]) 
      @file = DomainFile.find_by_id(params[:file_id])
    elsif @folder.id != 1
      @file = @folder
    end 
  	
    session[:cms_last_folder_id] = @folder.id if @folder
  	
    @file_manager_update = true
  	
    render :action => 'load_folder'
  end

  def update_icon_sizes
    @folder = DomainFile.find_folder(params[:folder_id])
    @load_request = params[:load_request]
    @icon_size = params[:icon_size]
    raise 'Invalid Folder' unless @folder
    
    file_ids = params[:file_ids].to_s.split(",").reject(&:blank?)
    if file_ids.length > 0
      @elements = @folder.children.find(:all,:conditions => { :id => file_ids  })
    else
      @elements = []
    end
    
    render :action => 'update_icon_sizes'
  end

  def popup
    folder_id = nil
    if params[:path] && params[:path][0]
      folder_id = params[:path][0].to_i
    elsif params[:file_id]
      folder_id = params[:file_id].to_i
    end

    @callback = params[:callback] || 'SCMS.setFileField'
    @mce = params[:mce]
    @popup = true
    
    @root_folder = DomainFile.root_folder
    
    if folder_id && folder_id.to_i > 0
      @folder = DomainFile.find_by_id(folder_id)
      
      if @folder && @folder.file_type != 'fld'
        @folder  = @folder.parent 
      end
    
    end
    if !@folder && session[:cms_last_folder_id]
      @folder = DomainFile.find_by_id_and_file_type(session[:cms_last_folder_id],'fld')
    end
    
    @folder= @root_folder unless @folder
    
    @selectedFolder = @folder.id
    
    raise 'Bad Folder' unless @folder
    
    session[:cms_last_folder_id] = @folder.id if @folder
    
    @onload = 'FileEditor.init();'
    render :action => 'index', :layout => @mce ? 'manage_mce' : 'manage_window'
  end
  
 def load_details
    @df = DomainFile.find_by_id(params[:file_id].to_i)
  end
  
  
  def file_manager_update

    if params[:upload_key]
      file_processor =  Workling.return.get(params[:upload_key])
      if file_processor && file_processor[:processed]
          @files = []
          @files = DomainFile.find(:all,:conditions => { :id => file_processor[:uploaded_ids] })
          session[:upload_file_worker] = nil
          @hide_item = true
          @file_manager_update = true
          render :partial => 'file_manager_update'
      else
        render :partial => 'file_manager_processing'
      end
    else
    	render :nothing => true
    end
  end
  
  def upload
  
    folder = DomainFile.find_by_id params[:upload_file][:parent_id]
    folder = nil unless folder.folder?

    if DomainFile.available_file_storage > 0 && folder
      encoding = params[:upload_file][:encoding]

      filenames = params[:upload_file][:filename]
      filenames = [filenames] unless filenames.is_a?(Array)

      domain_file_ids = filenames.collect do |filename|
        @upload_file = DomainFile.create(:filename => filename, :parent_id => folder.id, :encoding => encoding, :creator_id => myself.id, :skip_transform => true, :skip_post_processing => true)
        @upload_file.id
      end.compact
    
      worker_key = FileWorker.async_do_work(:domain_file_ids => domain_file_ids,
                                            :domain_id => DomainModel.active_domain_id,
                                            :extract_archive => params[:extract_archive],
                                            :replace_same => params[:replace_same]
                                            )
      @processing_key  = session[:upload_file_worker] = worker_key

      return render :json => {:processing_key => @processing_key} if params[:format] == 'json'

      respond_to_parent do 
        render :action => 'upload.rjs'
      end
    else
      respond_to_parent do 
        render :action => 'upload_failed.rjs'
      end
    end
  end

  def progress
    render :text => "{ state: 'not_configured' }"
  end
  
  def rename_file
    atr = params[:file] 
    
    @df = DomainFile.find(params[:file_id])
    
    if @df.name != atr[:name]
      @invalid_filename = true unless @df.rename(atr[:name])
    end
      
    render :action => 'rename_file'
  end
  
  def move_files
    
    file_ids = params[:file_id]
    folder_id = params[:folder_id]
    
    files = DomainFile.find(file_ids)
    
    files.each do |file|
      if file.parent.special == 'gallery' && file.parent.gallery
        img = file.parent.gallery.gallery_images.find_by_domain_file_id(file.id)
        img.domain_file_id = nil
        img.destroy if img
      end
      
      folder = DomainFile.find(:first,:conditions => ['file_type = "fld" AND id=?',folder_id])
      
      if active_module?('media') && folder.gallery
        gi = folder.gallery.gallery_images.create(:domain_file_id => file.id)
      end
      folder.children << file  
    end
      
    render :nothing => true
  end

  def processing_file
    @processing_key = params[:processing_key]
    return render :nothing => true unless @processing_key

    processor =  @processing_key ? Workling.return.get(@processing_key) : nil
    @processed = processor && processor[:processed]
    if @processed
      @file = DomainFile.find_by_id processor[:domain_file_id]
      session[:replace_file_worker] = nil
      session[:extract_file_worker] = nil
    end
  end

  def replace_file
    @file = DomainFile.find_by_id(params[:file_id].to_i)
    @replace = DomainFile.find_by_id(params[:replace_id].to_i)

    if @file && @replace && @file.id != @replace.id && ! @file.folder? && ! @replace.folder?
      worker_key = @file.run_worker(:replace_file, :replace_id => @replace.id)
      @processing_key  = session[:replace_file_worker] = worker_key
    else
      render :nothing => true
    end
  end
  
  def delete_revision
    @revision = DomainFileVersion.find_by_id(params[:revision_id].to_i)
    
    @file = @revision.domain_file
    
    @revision.destroy
    
    @selected_tab = 'Revisions'
  end
  
  def extract_revision
    @revision = DomainFileVersion.find_by_id(params[:revision_id].to_i)
    if @revision
      worker_key = @revision.run_worker(:extract_file)
      @processing_key  = session[:extract_file_worker] = worker_key
    else
      render :nothing => true
    end
  end
  
  def copy_file
    @file = DomainFile.find_by_id(params[:file_id].to_i)
    @file = @file.copy_file
  end

  def create_folder
     folder_id = params[:folder_id]
     
     parent_folder = DomainFile.find(folder_id)
     
     if parent_folder && parent_folder.folder?
     
      name = 'New Folder'.t
      @hide_item = true
      
      gallery_folder = Configuration.options.gallery_folder.to_i == parent_folder.id
      
      @folder = parent_folder.children.create(:creator_id => myself.id, :name => name,:file_type => 'fld',:special => gallery_folder ? 'gallery' : '')
      @parent_id = parent_folder.id
      if gallery_folder
        @folder.create_gallery(:name => name, :occurred_at => Time.now)
      end
      render :partial => 'create_folder'
     else
      render :nothing => true
     end
  end
  
  def delete_file
    file_id = params[:file_id]
    render :nothing => true unless file_id

    file = DomainFile.find(file_id)
    file.destroy
    render :nothing => true
  end
  
  def delete_files
    file_id = params[:file_id]
    render :nothing => true unless file_id

    files = DomainFile.find(file_id)
    dirs = []
    files.each do |fl|
      dirs += fl.storage_directories
    end

    key = DomainFile::LocalProcessor.set_directories_to_delete dirs
    url = "/website/transmit_file/delete/#{DomainModel.active_domain_id}/#{key}"
    Server.send_to_all url
    DomainFile::LocalProcessor.clear_directories_to_delete key

    files.each { |fl| fl.disable_destroy_remote; fl.destroy }

    render :nothing => true
  end
  
  
  def make_private
    file = DomainFile.find(params[:file_id].to_i)
    file.update_private!(true)
    
    file.reload

    render :partial => 'update_file',  :locals => { :file => file }
    
  end
  
  def make_public
  
    file = DomainFile.find(params[:file_id].to_i);
    file.update_private!(false)
    
    file.reload
    
    render :partial => 'update_file', :locals => { :file => file }
  
  end
  
  def folder_archive
    file = DomainFile.find(params[:folder_id].to_i)
    DomainModel.run_worker('DomainFile',file.id,:download_directory)
    render :nothing => true
  end
  
  def switch_processor
    file = DomainFile.find(params[:file_id].to_i)
    
    DomainModel.run_worker('DomainFile',file.id,:update_processor,{ :processor => params[:file_processor] })
    file.processor_status = 'processing'
    
    @select = params[:select] || 'img'

    render :partial => 'update_file', :locals => { :file => file }
  end
  
  def priv
    file_id = params[:path][0].to_i
    size = params[:path][1]
    
    domain_file = DomainFile.find(file_id)
    filename = domain_file.filename(size)
    mime_types =  MIME::Types.type_for(filename) 
    mime_types = ['application/x-gzip'] if domain_file.name =~ /\.webiva$/

    send_file(filename,
              :type => mime_types[0] ? mime_types[0].to_s : 'text/plain',
              :disposition => 'inline',
              :filename => domain_file.name)
  end
  
  def search
    srch = params[:search][:search]
    order = params[:search][:order]
    
    @results = DomainFile.run_search(srch,order)
    
    render :partial => 'search_results'
  
  end
  
  def edit_file
    @file = DomainFile.find(params[:file_id].to_i)
    
    @file = nil unless @file.editable?
    
    if(@file && params[:contents])
      @file.contents = params[:contents]
      @file.save
      render :partial => 'edited_file'
    else
      render :partial => 'edit_file'
    end
  end

  def update_storage
  end

  def export_status
    return render(:nothing => true) unless session[:download_worker_key]

    results = Workling.return.get session[:download_worker_key]

    @completed = false
    if results
      @completed = results[:processed] || results[:completed]
    end
    @failed = @completed && results[:domain_file_id].blank?

    session[:download_worker_key] = nil if @failed

    render :json => {:completed => @completed, :failed => @failed}
  end

  def export_file
    return render(:nothing => true) unless session[:download_worker_key]

    results = Workling.return.get session[:download_worker_key]
    session[:download_worker_key] = nil

    if results
      send_domain_file results[:domain_file_id], :type => results[:type]
    else
      render :nothing => true
    end
  end
  
  def import_status
    return render(:nothing => true) unless session[:import_worker_key]

    results = Workling.return.get session[:import_worker_key]

    if results
      @completed = results[:processed] || results[:completed]
      @failed = results[:valid] === false
      session[:import_worker_key] = nil if @completed || @failed
      render :json => results.slice(:initialized, :imported, :entries, :row, :error).merge(:completed => @completed, :failed => @failed)
    else
      render :json => {:completed => false, :failed => false, :initialized => false, :imported => 0, :entries => -1}
    end
  end
end
