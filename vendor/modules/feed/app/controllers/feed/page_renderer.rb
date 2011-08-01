require 'timeout'

class Feed::PageRenderer < ParagraphRenderer

  features '/feed/page_feature'

  paragraph :show

  def show
    @options = paragraph_options(:show)
    if !@options.url
      return render_paragraph :text => "[Configure Feed]"
    end
    filter = {}
    if @options.data_one.present?
       filter['d1'] = params['d1'] if params['d1'] =~ Regexp.new(@options.data_one)
       @invalid_params = true if filter['d1'].blank?
    end

    if @options.data_two.present?
       filter['d2'] = params['d2'] if params['d2'] =~ Regexp.new(@options.data_two)
       @invalid_params = true if filter['d2'].blank?
    end


    page_str = "#{CGI.escape(params['d1'].to_s)}_#{CGI.escape(params['d2'].to_s)}"[0..30]

    url = DomainModel.variable_replace(@options.url,filter)

    result = renderer_cache(nil,page_str,:expires => @options.cache_time * 60) do |cache|

      if @invalid_params
        @output = false
      else
        eater = Feed::GenericFeedEater.new(url,@options.format,@options.timeout)
        @output = eater.parse
      end
      if !@output 
        if editor?
          return render_paragraph :text => "Error Fetching Feed"
        else
          cache[:output] = feed_page_show_feature
        end
      else
        cache[:output] = feed_page_show_feature
      end
    end

    render_paragraph :text => result.output
  end


end
