
class Editor::SearchRenderer < ParagraphRenderer #:nodoc:all

  features '/editor/search_feature'

  paragraph :search_box
  paragraph :search_results
  paragraph :opensearch
  paragraph :opensearch_auto_discovery

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
    @options.search_results_page_id = site_node.id

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
      @pages, @results = @search.frontend_search(@options.search_order)
      @pages[:path] = @options.search_results_page_url
      @pages[:path] << '?'
      @pages[:path] << [:q, :per_page, :type].map { |ele| ! params[ele].blank? ? (ele.to_s + '=' + CGI.escape(params[ele])) : nil }.compact.join('&')

      self.update_search_stats
    end

    render_paragraph :feature => :search_page_search_results
  end

  def opensearch
    return render_paragraph :text => 'Reconfigure Data Output' unless paragraph.data
    return render_paragraph :text => 'Search results page not set' if paragraph.data[:search_results_page_id].blank?

    data = paragraph.data

    site_node = SiteNode.find data[:search_results_page_id]
    data[:search_results_page_url] = Configuration.domain_link site_node.node_path

    if data[:icon_id]
      domain_file = DomainFile.find_by_id data[:icon_id]
      if domain_file
	data[:icon] = { :url => Configuration.domain_link(domain_file.url), :width => 16, :height => 16, :type => 'image/x-icon' }
      end
    end

    if data[:image_id]
      domain_file = DomainFile.find_by_id data[:image_id]
      if domain_file
	data[:image] = { :url => Configuration.domain_link(domain_file.url), :width => 64, :height => 64, :type => domain_file.mime_type }
      end
    end

    data_paragraph :disposition => '', :type => 'text/xml', :data => render_to_string(:partial => '/editor/search/opensearch', :locals => { :data => data })
  end

  def opensearch_auto_discovery
    @options = (paragraph.data || {}).symbolize_keys

    if !@options[:module_node_id].blank? && @options[:module_node_id].to_i > 0
      @nodes = [ SiteNode.find_by_id(@options[:module_node_id]) ]
    else
      @nodes = SiteNode.find(:all,:conditions =>  ['node_type = "M" AND module_name = "/editor/opensearch"' ],:include => :page_modifier)
    end

    output = @nodes.collect do |nd|
      modifier_data = nd.page_modifier.modifier_data
      modifier_data ? "<link rel='search' type='application/opensearchdescription+xml' title='#{vh nd.page_modifier.modifier_data[:title]}' href='#{vh nd.node_path}' />" : ''
    end.join("\n")
    
    include_in_head(output)
    render_paragraph :nothing => true
  end

  protected

  def content_search_node
    return @search if @search
    @search = ContentNodeSearch.new :per_page => @options.default_per_page, :max_per_page => @options.max_per_page, :page => 1, :content_type_id => @options.content_type_id
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
    @search.page = params[:page].to_i if params[:page]
    @search.per_page = params[:per_page].to_i if params[:per_page]
    @search.category_id = params[:category].to_i unless params[:category].blank?
    if @search.content_type_id.nil?
      @search.content_type_id = params[:type].to_i if params[:type]
    end
    @search.published_after = params[:published_after]
    @search.published_before = params[:published_before]
    @search.valid?
  end

  def update_search_stats
    return unless @search.page == 1
    return if @search.terms.blank?

    return unless session[:domain_log_visitor] && session[:domain_log_visitor][:id]
    return if params[:skip]
    return if Configuration.options.search_stats_handler.blank?

    handler_info = get_handler_info(:webiva, :search_stats, Configuration.options.search_stats_handler)
    return unless handler_info

    visitor = DomainLogVisitor.find_by_id session[:domain_log_visitor][:id]
    handler_info[:class].update_search_stats(myself, visitor, @search)
  end
end
