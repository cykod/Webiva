# Copyright (C) 2009 Pascal Rettig.

require 'fileutils'

class FileWorker <  Workling::Base #:nodoc:all
  
  # Args: file_path
  # 
  def do_work(args)
  
    #ActiveRecord::Base.cms_setup
    logger.warn("In Do Work:")
    logger.warn Process.pid.to_s
    logger.warn("\n\n")
    
    domain = Domain.find_by_id(args[:domain_id])
    return false unless domain
    
    # Don't Save connection
    DomainModel.activate_domain(domain.attributes,'production',false)
  
    @uploaded_ids = []
    
    @processed = false 
    
    DomainFile.disable_post_processing
    
    tmp_dir= args[:tmp_dir]
    
    
    if args[:parent_id]
      parent_folder = DomainFile.find_by_id(args[:parent_id])
    end
    parent_folder = DomainFile.root_folder unless parent_folder 
    
    
    File.open(args[:filename]) do |file|
      @upload_file = DomainFile.create(:filename => file, :parent_id => parent_folder.id, :creator_id => args[:creator_id])
    end
    FileUtils.rm_rf(tmp_dir)
    
 
    is_gallery = parent_folder.special == 'gallery' ? true : false
    
    if(args[:extract_archive] && @upload_file.is_archive?)
      # If this is a gallery, extract all the files to the same folder
      extracted_files = @upload_file.extract(:single_folder => is_gallery,
                                             :file_types => is_gallery ? [ 'img'] : nil )
      if extracted_files.length > 0
        @uploaded_ids = extracted_files || []
        @upload_file.destroy
      else
        @uploaded_ids = []
      end
      
    else 
      if @upload_file.file_type == 'doc'  && !DomainFile.public_file_extensions.include?(@upload_file.extension.to_s.downcase)
        @upload_file.update_private!(true)
      end
      @uploaded_ids =  [ @upload_file.id ]
    end

    DomainFile.enable_post_processing
        
    DomainFile.find(@uploaded_ids).each do |df|
      df.post_process!(false)
    end
    
    if(args[:replace_same])
      @uploaded_ids = DomainFile.find(:all,:conditions => { :id => @uploaded_ids }).map { |fl| fl.replace_same }.map(&:id)
    end 
    
    Workling.return.set(args[:uid],{  :uploaded_ids => @uploaded_ids, :processed => true } )
  end

end
