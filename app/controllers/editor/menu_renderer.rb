# Copyright (C) 2009 Pascal Rettig.

class Editor::MenuRenderer < ParagraphRenderer #:nodoc:all

  features '/editor/menu_feature'
  
 def build_automenu_data(root,levels,excluded,page_path='',included=nil,locked=0)
    if root.is_a?(SiteNode)
      page = root
    else
       page = SiteNode.find_by_id(root)
       page = page.nested_pages if page
    end
    return [] unless page

    data = []
    page.child_cache.each do |page|
      page.menu.each do |pg|
        if (!included || locked <= 0 || included.include?(pg.id)) && !excluded.include?(pg.id)
          rev = pg.active_revision(paragraph.language)
          if rev || pg.node_type == 'F'
      	    if rev && !rev.menu_title.blank?
      	      title = rev.menu_title
	          elsif rev &&  !rev.title.blank? 
	            title = rev.title
	          else
	            title = pg.title.humanize.gsub("-"," ")
	          end
	          data << { :title => title,
	              :description => rev ? rev.meta_description : '',
		            :page => pg.id,
		            :link => pg.node_path + page_path,
		            :type => pg.node_type,
		            :menu => levels > 1 ? build_automenu_data(pg,levels-1,excluded,page_path,included,locked - 1) : nil,
		            :rev => rev
		          }
	
	        end
        end
      end
    end
    data
  end
  paragraph :automenu, :cache => true

  @@lock_level_hash = { 'no' => 0, 'yes' => 1000, 'one' => 1, 'two' => 2 }

  def automenu
    opts = paragraph.data
    
    if opts[:include_path]
      conn_type,conn_id = page_connection
      page_path = conn_id.blank? ? "" : "/" + conn_id 
    else 
      page_path = ''
    end
    
    request_path = "/" + (params[:full_path]||[]).join("/")
    
    if(opts[:root_page] && opts[:levels]) 
      lock_level =@@lock_level_hash[opts[:lock_level]] || 0
     
      data = { :url =>  request_path,
               :menu => build_automenu_data(opts[:root_page],opts[:levels],opts[:excluded] || [],page_path,lock_level > 0 ? opts[:included] : nil,lock_level)
             }
             
      data[:edit] = true if editor?

      render_paragraph :text => menu_feature(data)
    else
      render_paragraph :text => '[Please Configure Automenu]'.t
    end
 end
  
  # Caching options
  # Caching is always done on a per site node basis
  #  => true - Paragraph will be cached until changed
  #  => 5 - Paragraph will be cached for 5 minutes
  #  => :symbol
  paragraph :menu, :cache => true
  
  def generate_menu_urls(item)
    if(item[:dest] == 'page')
      nd = SiteNode.find_by_id(item[:url], :include => 'live_revisions',:order => 'page_revisions.language=' + DomainModel.connection.quote(paragraph.page_revision.language))
      if nd
        item[:page] = nd.id
        item[:type] = nd.node_type
        item[:rev] =  nd.live_revisions[0]
      end
      item[:link] =  nd ? nd.node_path : "/"
    else
      item[:link] = item[:url]
    end
    
    if item[:menu]
      item[:menu].each do |mnu|
        generate_menu_urls(mnu)
      end
    end
  end
  
  def menu
    data = paragraph.data || {}
    request_path = "/" + (params[:full_path]||[]).join("/")
    
    data[:url] = request_path
    data[:menu] ||= []
    
    data[:edit] = true if editor?
    
    data[:menu].each do |mnu|
      generate_menu_urls(mnu)
    end
    

    render_paragraph :text => menu_feature(data)
  end
  

  
  def build_site_map_data(page=nil,level=0)
    @page_access = true
    page_list = []
    if page.is_a?(SiteNode)
    
      page.site_node_modifiers.each do |mod|
	if mod.modifier_type == 'lock'
	  @page_access  = false
	elsif mod.modifier_type == 'page' && page.node_type == 'P'
	  # Only if we don't already have a lock disabling access
	  if @page_access 
	    if page.page_revisions.length > 0
	      if page.page_revisions.length > 1
		langs = page.page_revisions.collect do |rev|
		  { :title => rev.language.upcase, :link => "/view/#{rev.language.upcase}#{page.node_path}",
		    :description => rev.meta_description, :keywords => rev.meta_keywords }
		end
	      else
		langs = nil
	      end
	          
	      rev = page.page_revisions[0]
	      title = rev.menu_title.blank? ? ( rev.title.blank? ? page.title.humanize.gsub("-"," ") : rev.title ) : rev.menu_title.to_s
	      if page.include_in_sitemap?
		page_list << { :title => title , :link => page.node_path, :level => level, :languages => langs, :page_title => rev.title,
		  :description => rev.meta_description, :keywords => rev.meta_keywords }
	      end
	    end
	  end
	end
      end
    else
    
      page = SiteVersion.default.root_node if !page || page == 0
      page = SiteNode.find_by_id(page,:include => [ :site_node_modifiers, :page_revisions ], 
			  :conditions => 'active=1 AND revision_type="real" AND include_in_sitemap=1', :order => "site_node_modifiers.position, page_revisions.language = #{DomainModel.connection.quote(@language)} DESC" ) if(page.is_a?(Integer))
      
      return [] unless page
    end
    
    # Only if we don't already have a lock disabling access, get page chidlren
    if @page_access && page.children.count > 0
      page.children.find(:all,:include => [ :site_node_modifiers, :page_revisions ], 
                        :conditions => 'active=1 AND revision_type="real" AND include_in_sitemap=1', :order => "site_nodes.position, site_node_modifiers.position, page_revisions.language = #{DomainModel.connection.quote(@language)} DESC"
      ).each do |pg|
        page_list += build_site_map_data(pg,level+1)
      end
    end
    return page_list
  end
  
  paragraph :site_map
  
  def site_map
    opts = paragraph.data

    data = { :entries => build_site_map_data(opts[:root_page]) }
    render_paragraph :text => site_map_feature(data)
  end  
  

  
  def build_bread_crumb_data(root_page_id,page)
   return nil if !page 
   
   info = nil
   if page.node_type == 'P' || page.node_type == 'M'
    rev = page.visible_revision(@language)
    return nil if !rev
    
    
    title = rev.title.blank? ? page.title.humanize.capitalize : rev.title
    menu_title = rev.menu_title.blank? ? page.title.humanize.capitalize : rev.menu_title
    
    if title != ''
      info = [ { :title => title, :link => page.node_path, :page => page.id, :menu_title => menu_title } ]
    else
      info = []
    end
    
    if page.id != root_page_id && page.parent
      children = build_bread_crumb_data(root_page_id,page.parent)
      info = children + info if children
    end
   end
   info
  end

  paragraph :page_title 

  def page_title
    conn_type,conn_data = page_connection
    if conn_type == :title
      @title = conn_data
    end

    unless @title
      rev = revision
      if rev
        @title = rev.title.to_s.empty? ? site_node.title.humanize.capitalize : rev.title
      else
        @title = site_node.title.humanize
      end
    end
      
    render_paragraph :text => page_title_feature
  end
  
  def bread_crumbs
    opts = paragraph.data || {}
    
    rev = revision

    if rev
      title = rev.title.to_s.empty? ? site_node.title.humanize.capitalize : rev.title
      menu_title = rev.menu_title.blank? ? site_node.title.humanize.capitalize : rev.menu_title
    else
      title = site_node.title.humanize
      menu_title = site_node.title.humanize
    end

    conn_type,conn_data = page_connection
    if conn_type == :title
      title = conn_data
    end
      
    data = { :parent => build_bread_crumb_data(opts[:root_page],site_node.parent),
            :current => { :title => title,
                          :menu_title => menu_title,
                          :link => site_node.is_a?(SiteNode) ? site_node.node_path : '',
                          :page => site_node.id }
           }
    data[:edit] = true if editor?

    render_paragraph :text => bread_crumb_feature(data)
  end
  
  paragraph :bread_crumbs, :cache => true

end
