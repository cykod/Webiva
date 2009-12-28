class SearchController < CmsController

  cms_admin_paths :content,
    'Search' => { :action => 'index'} 
  

  @@results_per_page = 20

  def index
    cms_page_path ['Content'], 'Search'
    
    @search = params[:search]

    @content_type_id = params[:content_type_id].to_i

    @content_types = [['--All Content Types--',nil]] + ContentType.select_options

    @page = (params[:page]||0).to_i

    if !@search.blank?
        @results = content_search_handler(@search,@content_type_id==0 ? nil : @content_type_id,@page)

      if @results.length > 0
        @showing = (@page * @@results_per_page)+1
        @showing_end= @results.length + @showing-1
      end
    end

    

    render :action => 'index'
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
      @results = content_search_handler(search.strip)
    end
    
    render :action => 'autocomplete', :layout => false
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

  def content_search_handler(terms,content_type_id=nil,page=0)
    per_page = @@results_per_page

    language = Configuration.languages[0]
    conditions = content_type_id ? { :content_type_id => content_type_id } : nil
    @results, @total_results = ContentNode.search(language,terms,:conditions => conditions ,:limit => per_page+1,:offset => page.to_i * per_page)
    @results.map! do |node|
      content_description =  node.content_description(language)
      admin_url = node.admin_url
      if admin_url
        edit_title = admin_url.delete(:title)
        permission = admin_url.delete(:permission)
      else
        admin_url = '#'
      end

      if myself.has_content_permission?(permission)
        { 
          :title => node.title,
          :subtitle => content_description || node.content_type.content_name,
          :url => url_for(admin_url),
          :node => node
        }
      else 
        nil
      end
      
    end.compact!

    if @results.length > per_page
      @more = true
      @results.pop
    end
    
    @results
  end
end
