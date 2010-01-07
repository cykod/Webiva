class Media::MediaRenderer < ParagraphRenderer

  features '/media/media_feature'

  paragraph :video
  paragraph :audio
  paragraph :swf

  def video
    @options = paragraph_options(:video)

    @options.player.headers(self)

    @options.autoplay = false if editor?

    render_paragraph :feature => :media_media_video
  end

  def audio
    @options = paragraph_options(:audio)

    @options.player.headers(self)

    @options.autoplay = false if editor?

    render_paragraph :feature => :media_media_audio
  end

  def swf
    @options = paragraph_options(:swf)
  
    render_paragraph :feature => :media_media_swf
  end

end
