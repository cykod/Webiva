class Media::Players::Video::Base < Media::Players::Base
  def self.valid_media?(file)
    file.mime_type.include? 'video'
  end
end
