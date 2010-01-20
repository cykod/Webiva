class Media::Players::Audio::Base < Media::Players::Base
  def self.valid_media?(file)
    file.mime_type.include? 'audio'
  end
end
