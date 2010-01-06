class SearchController < CmsController #:nodoc:all

  cms_admin_paths :content,
    'Search' => { :action => 'index'} 
  
  skip_before_filter :validate_is_editor, :only => [:feeling_lucky, :suggestions]

  @@results_per_page = 20

  def index
    cms_page_path ['Content'], 'Search'
    
    @search = self.content_search_node

    if self.update_search && @search.search?
      @results, @more = content_search_handler

      if @results.length > 0
        @showing = ((@search.page-1) * @@results_per_page)+1
        @showing_end= @results.length + @showing-1
      end
    end

    opensearch_auto_discovery_header

    render :action => 'index'
  end

  def feeling_lucky
    if myself.id.nil? || ! myself.editor?
      session[:lockout_current_url] = self.request.request_uri
      return deny_access!
    end

    @search = self.content_search_node

    if self.update_search && @search.search?

      case @search.terms
      when /^(\/.*)/
	node = SiteNode.find(:first, :conditions => ['node_path = ? AND node_type="P"', "#{$1}" ])
	return redirect_to SiteNode.content_admin_url(node.id) if node

      when /^([a-zA-Z0-9]+)\:(.*)$/
	search_handler = $1
	search_terms = $2.strip

	if !search_terms.blank? && handler = search_handlers[search_handler]
	  if !handler[:class]
	    @results = self.send("#{handler[:name]}_search_handler",search_terms)
	  else
	    @results = handler[:class].send("#{handler[:name]}_search_handler",search_terms)
	  end

	  return redirect_to @results[0][:url] if @results && @results.length > 0
	end

      end

    end

    redirect_to :action => 'index', :search => @search.terms
  end

  protected 

  def search_handlers
    return @search_handlers if @search_handlers

    @search_handlers = { 
      'members' =>  { 
        :title => 'members: [member name or email address]',
        :subtitle => 'Search members by name or email',
        :text => 'members:'
      },
      'edit' =>  { 
        :title => 'edit: [/url/to_page]',
        :subtitle => 'Edit a page of the site',
        :text => 'edit:'
      }

    }
    @search_handlers.each do |name,hsh|
      hsh[:name] = name
      hsh[:subtitle] = hsh[:subtitle].t
    end

    @search_handlers
  end

  def opensearch_auto_discovery_header
    @domain = Domain.find DomainModel.active_domain_id

    opensearch_url = url_for :action => 'opensearch'

    @config = Configuration.options
    domain_name = @config.domain_title_name
    if domain_name.blank?
      @domain = Domain.find DomainModel.active_domain_id
      domain_name = @domain.name.humanize
    end

    title = "Backend search for %s" / domain_name
    @header = "<link rel='search' type='application/opensearchdescription+xml' title='#{vh title}' href='#{vh opensearch_url}' />"
  end

  public

  def autocomplete
    
    search = params[:search]

    case search
    when /^:$/
     @results = search_handlers.values
    when /^(\/.*)/
      @results = SiteNode.find(:all,:conditions => ['node_path LIKE ? AND node_type="P"', "%#{$1}%" ],:order => "LENGTH(node_path)").map do |node|
        {  :title => node.node_path,
           :url => node.node_path }
      end
    when /^([a-zA-Z0-9]+)\:(.*)$/
      search_handler = $1
      search_terms = $2.strip

      # Check if we match a search handler, if not show the handlers

      if !search_terms.blank? && handler = search_handlers[search_handler]
        if !handler[:class]
          @results = self.send("#{handler[:name]}_search_handler",search_terms)
        else
          @results = handler[:class].send("#{handler[:name]}_search_handler",search_terms)
        end
      else
        @results = search_handlers.values
      end
    else
      @search = self.content_search_node
      if self.update_search && @search.search?
	@results, @more = content_search_handler
      end
    end
    
    render :action => 'autocomplete', :layout => false
  end

  def suggestions
    search = params[:search]
    return render :json => [search, ['Not logged in']] unless myself.id && myself.editor?

    case search
    when /^:$/
     @results = search_handlers.values
    when /^(\/.*)/
      @results = SiteNode.find(:all,:conditions => ['node_path LIKE ? AND node_type="P"', "%#{$1}%" ],:order => "LENGTH(node_path)").map do |node|
        { :title => node.node_path,
	  :suggestion => node.node_path,
	  :subtitle => node.title,
	  :url => SiteNode.content_admin_url(node.id) }
      end
    when /^([a-zA-Z0-9]+)\:(.*)$/
      search_handler = $1
      search_terms = $2.strip

      # Check if we match a search handler, if not show the handlers

      if !search_terms.blank? && handler = search_handlers[search_handler]
        if !handler[:class]
          @results = self.send("#{handler[:name]}_search_handler",search_terms)
        else
          @results = handler[:class].send("#{handler[:name]}_search_handler",search_terms)
        end

	@results.map do |result|
	  result[:suggestion] = "#{search_handler}:#{result[:title]}"
	  result
	end if @results
      end
    end

    suggestions = []
    descriptions = []
    urls = []
    @results.each do |result|
      suggestions.push result[:suggestion]
      descriptions.push result[:subtitle]
      urls.push result[:url]
    end if @results

    render :json => [search, suggestions, descriptions, urls]
  end

  def opensearch
    search_url = url_for :action => 'feeling_lucky'
    suggest_url = url_for :action => 'suggestions'
    icon_url = Configuration.domain_link '/favicon.ico'

    @config = Configuration.options
    domain_name = @config.domain_title_name
    if domain_name.blank?
      @domain = Domain.find DomainModel.active_domain_id
      domain_name = @domain.name.humanize
    end

    title = '%s Search' / domain_name
    description = "Backend search for #{domain_name}"
    data = { :title => title, :description => description, :search_url => search_url, :suggest_url => suggest_url,
             :icon => {:url => icon_url, :width => 16, :height => 16, :type => 'image/x-icon'}
           }

    render :partial => 'opensearch', :locals => { :data => data }
  end

  protected

  def members_search_handler(terms)
    terms = terms.strip
    if terms.include?("@")
      users = EndUser.find(:all,:conditions => ['email LIKE ?', "%#{terms}%"],:limit => 10)
    elsif terms.split(" ").length > 1
      users = EndUser.find(:all,:conditions => [ 'full_name LIKE ?',"%#{terms}%" ], :limit => 10 )
    else
      users = (EndUser.find(:all,:conditions => [ 'full_name LIKE ?',"%#{terms}%" ],:limit => 5 ) + 
         EndUser.find(:all,:conditions => ['email LIKE ?', "%#{terms}%"],:limit => 5)).uniq
    end

    members_url = url_for(:controller => '/members',:action => 'view')
    users.map! do |usr|
      { :title => usr.email,
        :subtitle => usr.full_name,
        :url => members_url + "/" + usr.id.to_s
      }
    end
  end


  def edit_search_handler(terms)  
    language = Configuration.languages[0]
    

    edit_url = url_for(:controller => '/edit', :action => 'page' )
    @results = SiteNode.find(:all,:conditions => ['node_path LIKE ? AND node_type="P"', "%#{terms}%" ],:order => "LENGTH(node_path)",:include => :live_revisions).map do |node|
      rev = node.active_revisions.detect {  |rev| rev.language == language} || node.active_revisions[0]
        
      if(rev) 
        {  
          :title => "Edit Page: %s" / node.node_path,
          :subtitle =>  rev.title || node.title.humanize,
          :url => edit_url + "/page/#{node.id}"
        }
       end
      end.compact

  end

  def content_search_handler
    @results, @more = @search.backend_search

    @results.map! do |result|
      admin_url = result[:node].admin_url
      if admin_url
        edit_title = admin_url.delete(:title)
        permission = admin_url.delete(:permission)
      else
        admin_url = '#'
      end

      if myself.has_content_permission?(permission)
	result[:url] = url_for(admin_url)
	result
      else 
        nil
      end
      
    end.compact!

    @results.pop if @results.length > @search.per_page

    [@results, @more]
  end

  def content_search_node
    return @search if @search
    @search = ContentNodeSearch.new :per_page => @@results_per_page, :max_per_page => @@results_per_page, :page => 1
  end

  def searched
    return @searched if ! @searched.nil?
    @searched = params[:search]
  end

  def update_search
    return false unless self.searched

    @search.terms = params[:search]
    @search.page = params[:page] if params[:page]
    @search.per_page = params[:per_page] if params[:per_page]
    @search.content_type_id = params[:content_type_id] if params[:content_type_id]

    @search.valid?
  end
end
