
class Editor::SearchRenderer < ParagraphRenderer

  features '/editor/search_feature'

  paragraph :search_box
  paragraph :search_results

  def search_box
    @options = paragraph_options(:search_box)

    return render_paragraph :inline => 'Search results page not set' unless @options.search_results_page_url

    @search = self.content_search_node

    self.update_search

    result = renderer_cache(ContentNodeValue, nil, :skip => true) do |cache|
      cache[:output] = search_page_search_box_feature
    end

    render_paragraph :text => result.output
  end

  def search_results
    @options = paragraph_options(:search_results)

    return render_paragraph :inline => 'Search results page not set' unless @options.search_results_page_url

    if editor?
      @search = self.content_search_node
      @searched = true
      @pages = nil
      @results = [ {:title => 'Result 1', :subtitle => 'Page', :url => '/result1', :preview => '<pre>Result 1</pre>', :excerpt => 'lorem ipsum viverra dapibus eleifend. Pellentesque at lorem augue, ac suscipit felis. Praesent sollicitudin', :node => nil },
	           {:title => 'Result 2', :subtitle => 'Page', :url => '/result2', :preview => '<pre>Result 2</pre>', :excerpt => 'lorem ipsum viverra dapibus eleifend. Pellentesque at lorem augue, ac suscipit felis. Praesent sollicitudin', :node => nil }
                 ]
      return render_paragraph :feature => :search_page_search_results
    end

    @search = self.content_search_node
    @search.content_type_id = @options.content_type_id

    if self.update_search && @search.search?
      @pages, @results = @search.frontend_search
      @pages[:path] = @options.search_results_page_url
      @pages[:path] << '?'
      @pages[:path] << [:q, :per_page, :type].map { |ele| ! params[ele].blank? ? (ele.to_s + '=' + CGI.escape(params[ele])) : nil }.compact.join('&')
    end

    render_paragraph :feature => :search_page_search_results
  end

  protected

  def content_search_node
    return @search if @search
    @search = ContentNodeSearch.new :per_page => @options.default_per_page, :max_per_page => @options.max_per_page, :page => 1
    @search.set_protected_result myself
    @search
  end

  def searched
    return @searched if ! @searched.nil?
    @searched = params[:q]
  end

  def update_search
    return false unless self.searched

    @search.terms = params[:q]
    @search.page = params[:page] if params[:page]
    @search.per_page = params[:per_page] if params[:per_page]
    if @search.content_type_id.nil?
      @search.content_type_id = params[:type] if params[:type]
    end

    @search.valid?
  end
end
