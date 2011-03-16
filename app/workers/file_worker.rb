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
    DomainModel.activate_domain(domain.get_info,'production',false)
  
    @uploaded_ids = []
    
    @processed = false 
    
    DomainFile.disable_post_processing

    DomainFile.find(:all, :conditions => {:id => args[:domain_file_ids]}).each do |file|
      @upload_file = file

      @upload_file.generate_thumbnails

      @upload_file.update_attributes(:server_id => Server.server_id) if @upload_file.server_id != Server.server_id

      parent_folder = @upload_file.parent
 
      next unless parent_folder

      is_gallery = parent_folder.special == 'gallery' ? true : false
    
      if(args[:extract_archive] && @upload_file.is_archive?)
        # If this is a gallery, extract all the files to the same folder
        extracted_files = @upload_file.extract(:single_folder => is_gallery,
                                               :file_types => is_gallery ? [ 'img'] : nil )
        if extracted_files.length > 0
          @uploaded_ids += extracted_files
          @upload_file.destroy
        end
      else
        if @upload_file.file_type == 'doc'  && !DomainFile.public_file_extensions.include?(@upload_file.extension.to_s.downcase)
          @upload_file.update_private!(true)
        end
        @uploaded_ids << @upload_file.id
      end
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
