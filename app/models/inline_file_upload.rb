
class InlineFileUpload < HashModel
  attributes :file_id => nil, :object => nil, :field => nil, :url => nil, :folder_id => nil, :from => 'computer'

  validates_presence_of :file_id
  validates_presence_of :object
  validates_presence_of :file_id

  integer_options :folder_id
  domain_file_options :file_id

  def handle_file_upload(renderer, params)
    if ! params[:file][:url].blank?
      begin
        domain_file = DomainFile.create :filename => URI.parse(params[:file][:url]), :creator_id => renderer.myself.id
        params[:file][:file_id] = domain_file.id if domain_file.id
        self.file_id = domain_file.id
      rescue Exception => e
        Rails.logger.error e
      end
    else
      renderer.handle_file_upload(params[:file], 'file_id', {:folder => self.folder_id})
      self.file_id = params[:file][:file_id]
    end
  end

end
