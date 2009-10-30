# Copyright (C) 2009 Pascal Rettig.

class Editor::MenuRenderer < ParagraphRenderer

  features '/editor/menu_feature'
  
 def build_automenu_data(root,levels,excluded,page_path='',included=nil,locked=0)
    page = root.is_a?(SiteNode) ?  root : SiteNode.find_by_id(root)
    return [] unless page
    
    data = []
    page.children.each do |page|
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
      
      require_js('menu') if @include_menu_js
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
    require_js('menu') if @include_menu_js
  end
  
  # Site Map Feature
  feature :site_map, :default_data => { :entries => [ 
                                      { :title => 'Home Page', :level => 1, :link => "/" },
                                      { :title => 'Sub Page 1', :level => 2, :link => "/sub" },
                                      { :title => 'Sub Page 2', :level => 2, :link => "/sub2" }
                                     ]  
                                  },
    :default_feature => <<-FEATURE
  <div>
    <cms:entry>
      <div style="padding-left:<cms:level factor='10'/>px">
      <a <cms:href/>><cms:title/></a> 
      <cms:languages>
        ( <cms:language> <a <cms:href /> ><cms:title/></a> <cms:not_last>,</cms:not_last></cms:language> )
     </cms:languages>
      </div>     
    </cms:entry>
  </div>
FEATURE
  
  
  def site_map_feature(feature,data)
      parser_context = FeatureContext.new do |c|
        c.define_tag 'entry' do |tag|
          mnu = tag.globals.data[:entries]
          c.each_local_value(mnu,tag,'data')
        end
        
        c.define_tag 'href' do |tag|
          if data[:edit]
            if tag.locals.data[:page]
              "href='#{tag.locals.data[:link]}' onclick='cmsEdit.reloadPage(\"page\",#{tag.locals.data[:page]}); return false;'"
            else
              "href='#{tag.locals.data[:link]}' onclick='return false;'"
            end
          else
            "href='#{tag.locals.data[:link]}'"
          end
        end
        
        
        c.define_tag 'level' do |tag|
	        if !tag.single?
	          tag.locals.data[:level] == (tag.attr['value'] || 1).to_i  ? tag.expand : nil
	        else
	           tag.locals.data[:level] * (tag.attr['factor'] || 1).to_i
	        end
        end
        
        c.define_tag('url') {  |tag| tag.locals.data[:link] }
        c.define_tag('title') { |tag|  tag.locals.data[:title] }
        
        c.define_value_tag('description') { |tag| tag.locals.data[:description] }
        c.define_value_tag('keywords') { |tag| tag.locals.data[:keywords] }
        c.define_value_tag('page_title') { |tag| tag.locals.data[:page_title] }
                
        define_value_tag(c)
        
        c.define_expansion_tag('languages') { |tag| tag.locals.data[:languages].is_a?(Array) }
        
        c.define_tag 'language' do |tag|
          mnu =tag.locals.data[:languages] 
          c.each_local_value(mnu,tag,'data')
        end
        
        define_position_tags(c)
      end
      
      parser_context.globals.data = data
    
      parse_feature(feature,parser_context)
  end
  
  def build_site_map_data(page=nil,level=0)
    @page_access = true
    page_list = []
    if page.is_a?(SiteNode)
    
      page.site_node_modifiers.each do |mod|
	    if mod.modifier_type == 'L'
	      @page_access  = false
	    elsif mod.modifier_type == 'P' && page.node_type == 'P'
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
    
      page = SiteNode.get_root_folder if !page || page == 0
      page = SiteNode.find_by_id(page,:include => [ :site_node_modifiers, :page_revisions ], 
			  :conditions => 'active=1 AND revision_type="real" AND include_in_sitemap=1', :order => "site_node_modifiers.position, page_revisions.language = #{DomainModel.connection.quote(@language)} DESC" ) if(page.is_a?(Integer))
      
      return [] unless page
    end
    
    # Only if we don't already have a lock disabling access, get page chidlren
    if @page_access && page.children_count > 0
      page.children.find(:all,:include => [ :site_node_modifiers, :page_revisions ], 
                        :conditions => 'active=1 AND revision_type="real" AND include_in_sitemap=1', :order => "site_nodes.position, site_node_modifiers.position, page_revisions.language = #{DomainModel.connection.quote(@language)} DESC"
      ).each do |pg|
        page_list += build_site_map_data(pg,level+1)
      end
    end
    return page_list
  end
  
  paragraph :site_map, :cache => true
  
  def site_map
    opts = paragraph.data
    
    data = { :entries => build_site_map_data(opts[:root_page]) }
    render_paragraph :text => site_map_feature(get_feature('site_map'),data)
  end  
  
 # Bread Crumbs Feature
  feature :bread_crumb, :default_data => { :parents => [ 
                                      { :title => 'Root',  :link => "/" },
                                      { :title => 'Parent', :link => "/sub" }
                                     ],
                                     :current => { :title => 'Current Page',
                                                   :link => '/sub/goober' }
                                  },
    :default_feature => <<-FEATURE
  <div>
    <cms:parent>
      <cms:level value='1'>
        <b><a <cms:href/> ><cms:title/></a></b> &gt;
      </cms:level>
      <cms:not_level value='1'>
        <a <cms:href/> ><cms:title/></a> &gt; 
      </cms:not_level>
    </cms:parent>
    <cms:current>
      <cms:title/>
    </cms:current>
  </div>
FEATURE
  
  def bread_crumb_feature(feature,data)
      parser_context = FeatureContext.new do |c|
        c.define_tag 'parent' do |tag|
          # Go through each section
          # Set the local to this
          result = ''
          mnu = tag.globals.data[:parent]
          if mnu.is_a?(Array)
            mnu.each_with_index do |entry,idx|
              tag.locals.level = idx + 1
              tag.locals.data = entry
              tag.locals.first = entry == mnu.first
              tag.locals.last =  entry == mnu.last
              result << tag.expand
            end
          end
          result
        end
        
        c.define_tag 'current' do |tag|
            tag.locals.data = tag.globals.data[:current]
            tag.locals.first = true
            tag.locals.last = true
            tag.expand
        end
        
        c.define_tag 'href' do |tag|
          if data[:edit]
            if tag.locals.data[:page]
              "href='#{tag.locals.data[:link]}' onclick='cmsEdit.reloadPage(\"page\",#{tag.locals.data[:page]}); return false;'"
            else
              "href='#{tag.locals.data[:link]}' onclick='return false;'"
            end
          else
            "href='#{tag.locals.data[:link]}'"
          end
        end
        
        c.define_tag 'level' do |tag|
          if tag.locals.level == tag.attr[:value].to_i
            tag.expand
          else
            ''
          end
        end
        
        c.define_tag 'not_level' do |tag|
          if tag.locals.level != tag.attr[:value].to_i
            tag.expand
          else
            ''
          end
        end
        
        c.define_tag 'url' do |tag|
          tag.locals.data[:link]
        end
        
        c.define_tag 'title' do |tag|
          tag.locals.data[:title]
        end
        
        c.define_tag 'menu_title' do |tag|
          tag.locals.data[:menu_title]
        end 
        
        define_position_tags(c)
      end
      
      parser_context.globals.data = data
    
      parse_feature(feature,parser_context)
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
            
    render_paragraph :text => bread_crumb_feature(get_feature('bread_crumb'),data) 
  end
  
  paragraph :bread_crumbs, :cache => true

end
