
class TransmitFileController < ApplicationController

  before_filter :fetch_domain_file

  def file
    filename = @domain_file.filename(@file_size)
    mime_types =  MIME::Types.type_for(filename) 
    send_file(filename,
              :type => mime_types[0] ? mime_types[0].to_s : 'text/plain',
              :disposition => 'inline',
              :filename => @domain_file.name)
  end

  def delete
    dir = @domain_file.abs_storage_directory
    Rails.logger.error "removing folder #{dir}"
    FileUtils.rm_rf(dir) if File.directory?(dir)
    render :nothing => true
  end

  protected

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
    @file_size = params[:path][3]

    raise 'No file specified' unless @file_id
    raise 'No file specified' if server_hash.blank?

    @domain_file = DomainFile.find_by_id(@file_id)
    @domain_file = nil if @domain_file && @domain_file.server_hash != server_hash
    raise 'File not found' unless @domain_file
  end
end
