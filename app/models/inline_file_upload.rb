
class InlineFileUpload < HashModel
  attributes :file_id => nil, :object => nil, :field => nil

  validates_presence_of :file_id
  validates_presence_of :object
  validates_presence_of :file_id

  domain_file_options :file_id
end
