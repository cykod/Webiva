
class Editor::SearchRenderer < ParagraphRenderer

  features '/editor/search_feature'

  paragraph :search_box
  paragraph :search_results

  def search_box
    @options = paragraph_options(:search_box)
    @search = self.content_search_node

    self.update_search

    result = renderer_cache(ContentNodeValue, nil, :skip => self.searched) do |cache|
      cache[:output] = search_page_search_box_feature
    end

    render_paragraph :text => result.output
  end

  def search_results
    @options = paragraph_options(:search_results)
    @search = self.content_search_node

    if self.update_search && @search.search?
      @results, @total_results = @search.frontend_search
    end

    render_paragraph :feature => :search_page_search_results
  end

  protected

  def content_search_node
    return @search if @search
    @search = ContentNodeSearch.new :per_page => @options.default_per_page, :max_per_page => @options.max_per_page, :page => 0
    @search.set_protected_result myself
    @search
  end

  def searched
    return @searched if ! @searched.nil?
    @searched = request.post? && params[:search]
  end

  def update_search
    return false unless self.searched

    @search.terms = params[:search][:terms]
    @search.page = params[:search][:page] if params[:search][:page]
    @search.per_page = params[:search][:per_page] if params[:search][:per_page]
    @search.content_type_id = params[:search][:content_type_id] if params[:search][:content_type_id]

    @search.valid?
  end
end
