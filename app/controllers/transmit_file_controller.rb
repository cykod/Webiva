
class TransmitFileController < ApplicationController

  before_filter :fetch_domain_file, :except => [:delete]

  def file
    # this is for existing sites
    unless @domain_file.mtime
      # this should always be true, but just in case make sure the mtime is only coming from the owner
      if @domain_file.server_id == Server.server_id
        @domain_file.mtime = File.mtime(@domain_file.local_filename)
        @domain_file.save
      end
    end

    filename = @domain_file.filename params[:size]

    if !File.exists?(filename)
      @domain_file.ensure_thumbnail(params[:size])
    end
    mime_types =  MIME::Types.type_for(filename) 
    send_file(filename,
              :type => mime_types[0] ? mime_types[0].to_s : 'text/plain',
              :disposition => 'inline',
              :filename => @domain_file.name)
  end

  def file_version
    @file_version_id = params[:path][3]
    raise 'File not found' unless @file_version_id

    @domain_file_version = @domain_file.versions.find_by_id @file_version_id
    raise 'File not found' unless @domain_file_version
    raise 'File not found' unless @domain_file_version.server_id == Server.server_id

    filename = @domain_file_version.filename
    mime_types =  MIME::Types.type_for(filename) 
    send_file(filename,
              :type => mime_types[0] ? mime_types[0].to_s : 'text/plain',
              :disposition => 'inline',
              :filename => @domain_file_version.name)
  end

  def delete
    key = params[:path][1]
    DomainFile::LocalProcessor.get_directories_to_delete(key).each do |dir|
      dir = "#{RAILS_ROOT}/public" + dir
      FileUtils.rm_rf(dir) if File.directory?(dir)
    end

    render :nothing => true
  end

  protected

  def rescue_action_in_public(exception,display = true) # :nodoc:
  end

  def activate_domain(domain=nil)
    raise "Unknown server #{request.host}" unless Server.server_name == request.host

    domain = Domain.find_by_id params[:path][0]
    unless domain
      raise 'No Domain Info'
    end

    # Activate the correct DB connection
    unless DomainModel.activate_domain(domain.get_info, 'production')
      raise 'Invalid Domain Info'
      return false
    end

    true
  end

  def fetch_domain_file
    @file_id = params[:path][1].to_i
    server_hash = params[:path][2]

    raise 'No file specified' unless @file_id
    raise 'No file specified' if server_hash.blank?

    @domain_file = DomainFile.find_by_id(@file_id)
    @domain_file = nil if @domain_file && @domain_file.server_hash != server_hash
    raise 'File not found' unless @domain_file
    @domain_file
  end
end
