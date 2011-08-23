# Copyright (C) 2009 Pascal Rettig.


# Based class for Site Node Module dispatcher support
class ModuleDispatcher
  attr_reader :title

  def initialize(site_node)
    @site_node = site_node
  end


  def self.available_pages(*pages)
    cur_pages = {}
    
    pages.each do |pg| 
      cur_pages[pg[0]] = pg
    end
    
    define_method "pages" do
      cur_pages
    end
    
    define_method "page_list" do
      pages
    end
    
  
  end
  
  def run(path)
    path = path.clone
    
    args = []
    while 1
      cur_path = "/" + path.join("/")
      
      
      if pages[cur_path]
        page = pages[cur_path]
        @title = page[2]
        return self.send(page[1],args)
      end
      
      args.unshift(path.slice!(-1))
      if cur_path == '/'
        raise "Invalid Page"
      end
      
    end
  end
  
  # Generate a menu from the available pages
  def menu
    levels = { @site_node.node_level => [] }
    
    page_num = 0
  
    self.page_list.each do |page|
      page_num += 1
      if page[4]
        level = page[4] + @site_node.node_level
        node_path = (@site_node.node_path + page[0]).gsub(/\/$/,'')
        node = SiteNode.new(:node_type => "F",
                            :node_path => node_path,
                            :module_name => @site_node.module_name,
                            :node_level => level,
                            :title => (page[3] || page[2]).t
                            )
        node.id = 1000000 + page_num
        levels[level-1] ||= [] unless levels[level-1] # To Catch any errors
        levels[level-1] << node
        levels[level] = node.child_cache
      end
    
    end
  
   # Return the menu from the base 
   levels[@site_node.node_level]
  end
  
  protected
  
  def simple_dispatch(zone_idx,controller,paragraph,options = {})
    paragraph_id = options[:paragraph_id] ||  1
    

    para = PageParagraph.thaw(:zone_idx => zone_idx,
                             :position => 1,
                             :display_type => paragraph,
                             :display_module => controller,
                             :site_module_id => @site_module)
    para.id = -paragraph_id
    para.content_publication_id = options[:content_publication_id]
    para.site_feature_id = options[:site_feature_id]
    para.set_page_connections(options[:connections] || {})
    para.module_paragraph = true
    para.data = options.delete(:data) || {}
    
    [ para ]
                              
  end
end
