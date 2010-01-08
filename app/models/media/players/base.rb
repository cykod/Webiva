class Media::Players::Base
  def initialize(options)
    @options = options
  end

  def render_player(container_id)
  end

  def headers(renderer)
    nil
  end

  def self.valid_media?(file)
    raise 'Must implement'
  end
end
