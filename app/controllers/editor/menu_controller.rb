# Copyright (C) 2009 Pascal Rettig.

class Editor::MenuController < ParagraphController #:nodoc:all

  
  # Make sure we are the editor for menu and automenu paragraphs as well as site maps 
  editor_header "Navigation Paragraphs", :paragraph_navigation
  editor_for :automenu, :name => 'Automatic Menu', :feature => 'menu', 
                        :inputs => [ [ :path, 'Page Path',:integer ] ]
  editor_for :menu, :name => 'Links Menu', :feature => 'menu'
  editor_for :site_map, :name => 'Site Map', :feature => 'site_map'
  editor_for :bread_crumbs, :name => 'Bread Crumbs', :feature => 'bread_crumb'

  editor_for :page_title, :name => "Page Title", :inputs => [ [ :title,"Page Title",:title_str]], :feature => :page_title, :no_options => true

  def menu
  
      @data = @paragraph.data || {}
    
      @data[:menu] ||= []
      
      @pages = SiteNode.page_options()
  end
  
  def menu_save
     # Save the incoming paragraph
     item_keys = params[:item] ? params[:item].keys : []
     item_keys.sort!
     
     
     
     last_level = 1
     data={:menu => [] }
     level_parents = [data]
     cur = data[:menu]
     item_keys.each do |item_key|
        item = params[:item][item_key]
        level = item[:level].to_i || 1
        item = { :title => item[:title],
                 :dest => item[:dest] == 'page' ? 'page' : 'url',
                 :url => item[:dest] == 'page' ? item[:url].to_i : item[:url] }
        level_parents[level] = item
        
        if(level == last_level)
          cur << item
          level_parents[level] = item
        elsif(level > last_level) 
          cur.last[:menu] ||= []
          cur = cur.last[:menu]
          cur << item
        else
          cur =  level_parents[level-1][:menu]
          cur << item
        end 
        last_level = level
     end
     
     @paragraph.data = data
     @paragraph.save
     # Then render a RJS template that renders the paragraph
     
     render_paragraph_update
  end
  
  class AutomenuOptions < HashModel
    default_options :root_page => nil, :levels => nil, :excluded => [],:lock_level => 'no', :included => [], :include_path => false
      
    boolean_options :include_path
    integer_options :levels, :root_page
    page_options :root_page
    validates_presence_of :root_page
    validates_presence_of :levels
    integer_array_options :included, :excluded

    def is_locked?
      self.lock_level != 'no'
    end
  end
  
  def build_preview(root,levels,excluded,cur_level=1)
    page = root.is_a?(SiteNode) ?  root : SiteNode.find_by_id(root)
    
    return nil unless page 
    mnu = []
    elem_ids = []
    page.children.each do |page|
      page.menu.each do |pg|
        rev = pg.active_revision(@revision.language)
        if rev && !rev.menu_title.blank?
  	      title = rev.menu_title
        elsif rev &&  !rev.title.blank? 
          title = rev.title
        else
          title = pg.title.humanize 
        end
        title = "[blank]".t if title.blank?
        children,subelem_ids =  levels > 1 ? build_preview(pg,levels-1,excluded,cur_level+1) : [ nil,[]] 
        mnu << { :title => title,
          :node_id => pg.id,
          :excluded => excluded.include?(pg.id),
          :children => children
        }
        elem_ids += [pg.id] + subelem_ids
      end
    end
    [mnu,elem_ids]
  end
  
  def automenu
    data = params[:menu] || @paragraph.data
    @menu = AutomenuOptions.new(data)

    @preview, @elem_ids = build_preview(data[:root_page],data[:levels].to_i,data[:excluded] || []) if data[:root_page]
    
    @pages = [['---Select Page---'.t,'']] + SiteNode.page_and_group_options("Site Root".t)
    @levels = [ ["1 Level",1] ] + 
      ( 2..5 ).to_a.collect do |num|
         [sprintf("%d Levels".t,num), num ]
      end
      
    if request.post?
      if @menu.valid?
        if @menu.lock_level != 'no'
          @menu.included = []
          @elem_ids.each { |elm| @menu.included << elm if(!@menu.excluded.include?(elm)) }
        end
        @paragraph.data = @menu.to_h
        @paragraph.save
        render_paragraph_update
        return
      end
    end

    if @menu.is_locked? && ! request.post?
      included = @menu.included || []
      (@elem_ids||[]).each do |elm|
        unless included.include?(elm)
          @menu.excluded << elm
          @preview.each { |item| item[:excluded] = true if item[:node_id] == elm }
        end
      end
      @menu.excluded.uniq!
    end    
    
    @excluded = @menu.excluded

    render :action => 'automenu'
  end
  
  def automenu_preview()
    @excluded = ( params[:menu][:excluded] || []).collect { |elm| elm.to_i }
  
    @preview, @elem_ids = build_preview(params[:menu][:root_page],params[:menu][:levels].to_i,@excluded)
    render :partial => 'automenu_preview'
  end
  
  class SiteMapOptions < HashModel
    attributes :root_page => nil
  
    integer_options :root_page
    page_options :root_page
    
     options_form(
	  fld(:root_page, :select, :options => :page_options)
	  )

    def self.page_options
      @opts = [['Show Entire Site'.t, nil]] + SiteNode.page_options
    end
  end
  
  class BreadCrumbsOptions < HashModel
    attributes :root_page => nil

    integer_options :root_page
    page_options :root_page
    
     options_form(
	  fld(:root_page, :select, :options => :page_options)
	  )

    def self.page_options
      @opts = [['No Root Page'.t, nil]] + SiteNode.page_options
    end
  end
end
