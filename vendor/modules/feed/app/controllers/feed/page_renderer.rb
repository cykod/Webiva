require 'timeout'

class Feed::PageRenderer < ParagraphRenderer

  features '/feed/page_feature'

  paragraph :show

  def show
    @options = paragraph_options(:show)
    if !@options.url
      return render_paragraph :text => "[Configure Feed]"
    end
    result = renderer_cache(nil,nil,:expires => @options.cache_time * 60) do |cache|
      eater = Feed::GenericFeedEater.new(@options.url,@options.format,@options.timeout)
      @output = eater.parse
      logger.error('Refetching Feed')
      if !@output
        if editor?
          return render_paragraph :text => "Error Fetching Feed"
        else
          cache[:output] = ''
        end
      else
        cache[:output] = feed_page_show_feature
      end
    end

    render_paragraph :text => result.output
  end


end
