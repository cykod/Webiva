# Copyright (C) 2009 Pascal Rettig.

require "digest/sha1"

class DomainFileVersion < DomainModel

  belongs_to :domain_file
  
  serialize :meta_info
  
  after_destroy :erase_version_file
  after_create :move_version_file # Move file original file to the version location
  
  belongs_to :creator, :class_name => 'EndUser',:foreign_key => 'creator_id'
  
  def self.archive(file)

    if !file.processor_handler.revision_support
      begin
        file.destroy_thumbs
        File.unlink(file.filename)
      rescue Exception => e
        raise e
        # Chomp
      end
      return
    end
  
    info = {}
    if file.image_size
      info[:image_size] = { :width => file.width, :height => file.height }
    end
    
    version_hash = self.generate_version_hash

    file.processor_handler.destroy_remote! # get rid of remote copies of this file

    file.filename # copy file locally
    
    # Create a new instance with the correct file attributes
    v = DomainFileVersion.create(:domain_file => file,
                                 :filename => file.read_attribute(:filename),
                                 :file_type => file.file_type,
                                 :meta_info => info,
                                 :extension => file.extension,
                                 :prefix => self.generate_version_prefix(file.prefix,version_hash),
                                 :file_size => file.file_size,
                                 :creator_id => file.creator_id,
                                 :version_hash => version_hash,
                                 :stored_at => file.stored_at,
                                 :server_id => Server.server_id)
  end
  
  
  # Create a domain file from this file
  def extract(user_id=nil)
    self.copy_local!
    return nil unless File.exists?(self.abs_filename)

    df = DomainFile.new(:parent_id => self.domain_file.parent_id, :creator_id => user_id || self.creator_id, :private => self.domain_file.private, :process_immediately => true)
    File.open(self.abs_filename,"rb") do |f|
      df.filename = f
      if(df.save)
        return df
      end
    end
  end

  def extract_file(options={})
    file = self.extract
    {:domain_file_id => file.id} if file
  end

  def prefixed_filename
    # unless we have a filename, return false
    atr = self.read_attribute(:filename)
    return nil unless self.prefix && atr
     "#{DomainFile.storage_subdir}/#{self.prefix}/#{atr}"
  end
  
   def relative_filename
      # unless we have a filename, return false
      atr = self.read_attribute(:filename)
      return nil unless self.prefix && atr
    self.storage_directory + atr
   end
   
   # Return the absolute storage directory - valid for opening a file  on the server 
   # Return the relative storage directory
   # Thumbnails are stored in subdirectories prefixed with the file size (../small/file.jpg)
   def abs_filename; "#{RAILS_ROOT}/public" + self.relative_filename; end
   alias_method :filename, :abs_filename
   
   def name
     self.read_attribute(:filename)
   end
   
   def storage_directory; self.storage_base + "/" + self.prefix + "/"; end
   def abs_storage_directory; "#{RAILS_ROOT}/public" + self.storage_base + "/" + self.prefix + "/"; end
   
   def storage_base; self.domain_file.private? ? DomainFile.private_storage_base : DomainFile.public_storage_base; end
   
   def url
     if domain_file.processor != 'local'
       self.domain_file.processor_handler.version_url(self)
     else
       relative_filename
     end
   end
   
   ###########
   # Hooks
   ###########
   
   def erase_version_file
    self.domain_file.processor_handler.destroy_remote_version!(self)
    if !prefix.blank? && (File.directory?(abs_storage_directory))
      FileUtils.rm_rf(abs_storage_directory)
    end
  end
  
  def move_version_file
      FileUtils.mkpath(self.abs_storage_directory)
      File.mv(self.domain_file.filename,self.filename)
      self.domain_file.destroy_thumbs
      self.domain_file.processor_handler.create_remote_version!(self) if self.domain_file.processor != 'local'
  end
 
  def width
    return nil unless self.meta_info[:image_size]
    self.meta_info[:image_size][:width]
  end
  
  def height
    return nil unless self.meta_info[:image_size]
    self.meta_info[:image_size][:height]
  end

  def server
    @server ||= Server.find_by_id(self.server_id) if self.server_id
  end

  def copy_local!
    self.domain_file.processor_handler.respond_to?('copy_version_local!') ? self.domain_file.processor_handler.copy_version_local!(self) : false
  end

 protected
  def self.generate_version_hash
    now = Time.now
    digest  = Digest::SHA1.hexdigest("#{now}#{rand}#{now.usec}#{Process.pid}")[0..31]
  end

  def self.generate_version_prefix(prefix,version_hash)
    "#{prefix}/v/#{version_hash}"
  end
  
end
