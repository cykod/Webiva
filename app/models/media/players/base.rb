class Media::Players::Base
  def initialize(options)
    @options = options
  end

  def render(container_id)
  end

  def headers(renderer)
  end

  def self.valid_media?(file)
    raise 'Must implement'
  end
end
