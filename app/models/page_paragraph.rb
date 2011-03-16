# Copyright (C) 2009 Pascal Rettig.

class PageParagraph < DomainModel
  attr_accessor :locked
  attr_accessor :hidden
  attr_accessor :framework
  
  attr_accessor :params
  
  attr_accessor :rendered_output
  attr_accessor :feature_body
  
  attr_accessor :page_connections
  attr_accessor :module_paragraph
  
  attr_accessor :render_css
  
  attr_writer  :language
  
  belongs_to :site_feature
  
  serialize :data
  serialize :connections

  belongs_to :page_revision
  belongs_to :site_module
  belongs_to :content_publication


  named_scope :live_paragraphs, {:joins => :page_revision, :conditions => 'page_revisions.active=1 AND page_revisions.revision_type="real"'}
  named_scope :with_feature, lambda { |display_module, display_type| {:conditions => ['display_module = ? and display_type = ?', display_module, display_type]} }

  # PageParagraph file instance support is in PageRevisions
  # process_file_instance :display_body, :display_body_html
  apply_content_filter(:display_body =>  :display_body_html) do |para|
    { :filter => para.paragraph_filter }
  end

  def paragraph_filter
    if self.display_module.blank?
      case display_type
      when 'code' : 'full_html'
      when 'textile' : 'textile'
      when'markdown' : 'markdown'
      end
    else
      nil
    end
  end

  def validate_markup
    if self.paragraph_filter
      validator = Util::HtmlValidator.new(self.display_body)
      validator.validate
    else
      nil
    end
  end
  
  def post_process_content_filter_display_body
    # Most Instance Support is in page_revisions
  end
  
  def regenerate_file_instances
    file_instance_search('display_body')
    file_instance_update('display_body','display_body_html')
  end

  has_triggered_actions  
  
#  validates_presence_of :page_revision

  def language
    @language || (self.page_revision ? self.page_revision.language : Configuration.languages[0] )
  end
  
  def before_create
    if self.identity_hash.blank?
      self.identity_hash = DomainModel.generate_hash
    end
    self.display_body ||= ''
    unless self.data.is_a?(Hash)
      self.send(:data=,{})
    end
  end
  
  def renderer
    # Built in paragraph don't have display modules
    return nil if self.display_module.blank?
    
    # Get an array
    if display_module[0..0] == '/'
      disp = display_module[1..-1].split("/") 
    else
      disp = display_module.split("/") 
    end
    # Get rid of any leading /
    # disp.shift if disp[0] || disp[0] == ''
    
    # Get us Editor::MenuRenderer
    className = disp.map { |elem| elem.camelcase }.join("::") + 'Renderer' 

    cls = className.constantize
    
    cls
  end
  
  def feature_type
    if self.content_publication
      self.content_publication.feature_name
    else
      self.editor_info[:feature]
    end
  end
  
  def editor_class
    return nil unless self.display_module
    
    disp = display_module.split("/") 
    # Get rid of any leading /
    disp.shift if disp[0] || disp[0] == ''
    
    # Get us Editor::MenuController
    className = display_module.map { |elem| elem.camelcase }.join("::") + 'Controller' 
    cls = className.constantize
  end

  def editor_info
    cls = editor_class
    return unless cls
    
    cls.send(self.display_type.to_s + "_info")
  end
  
  def info
    cls = self.renderer
    return unless cls
    cls.send("paragraph_info_" + self.display_type)
  end
  
  def framework?
    @framework
  end
  
  

  def set_page_connections(conns)
   @page_connections ||= {}

    if self.connections
      conns.each do |key,val|
        @page_connections[key.to_sym] = [ self.connections[:inputs][key.to_sym][2],val ]
      end
    else
      conns.each do |key,val|
        @page_connections[key.to_sym] = [ key,val[1] ]
      end
    end
   
  end
  
  # Let us set the page connections directly, instead of by type (used in testing)
  def direct_set_page_connections(conns)
   @page_connections ||= {}
   conns.each do |key,val|
     @page_connections[key.to_sym] = val
   end
  end
    
  
  def display_module_identifier
      self.display_module.gsub("/","_")
  end

  def add_paragraph_input!(input_name,other_para,conn_type,identifier)
    self.connections ||= { }
    self.connections[:inputs] ||= { }
    self.connections[:inputs][input_name.to_sym] = [ other_para.identity_hash, conn_type.to_sym, identifier.to_sym]
    
    other_para.connections ||= { }
    other_para.connections[:outputs] ||= []
    other_para.connections[:outputs] << [ identifier.to_sym, self.identity_hash, input_name.to_sym ]
    other_para.save
    self.save
  end

  def add_page_input(input_name,conn_type,identifier)
    self.connections ||= { }
    self.connections[:inputs] ||= { }
    self.connections[:inputs][input_name.to_sym] = [ "0", conn_type.to_sym, identifier.to_sym]
  end
  
  def page_connection(name)
    @page_connections  ||= {}
    @page_connections[name.to_sym]
  end
  
  def cache_attributes
    atr = self.attributes
    atr[:render_css] = self.site_feature && !self.site_feature.rendered_css.blank?
    atr[:module_paragraph] = @module_paragraph
    atr[:page_connections] = @page_connections
    atr
  end
  
  def self.thaw(atr)
    para_id = atr.delete('id') || atr.delete(:id)
    para = PageParagraph.new(atr)
    para.connections.symbolize_keys! if para.connections
    para.connections.each { |key,hsh| hsh.symbolize_keys! if hsh.is_a?(Hash) } if para.connections
    para.id = para_id
    para
  end

  def triggers
    info = self.editor_info
    if info && info[:triggers]
      info[:triggers].collect { |trig| [ trig[0].t,trig[1] ] }
    else
       nil
    end
  end
  
  def display
    self.display_body_html.blank? ? self.display_body : self.display_body_html
  end

  def paragraph_options
    return nil unless display_module
    self.editor_class.paragraph_options(display_type,self.data)
  end
  

  def link_canonical_type!(override = false)
    opts = paragraph_options
    return nil unless opts
    opts.class.current_canonical_opts.each do |opt|
      canonical_type = opt[0]
      if canonical_type == 'ContentType'
        link_canonical_content_type!(opts,opt,override)
      elsif canonical_type == 'ContentMetaType'
        link_canonical_meta_type!(opts,opt,override)
      end
    end
  end

  def fix_paragraph_options(from_version, to_version, opts={})
    options = paragraph_options
    return unless options
    if options.fix_page_options(to_version)
      self.data = options.to_h(:skip => true)
      self.save
    end
  end

  private

  def link_canonical_content_type!(opts,opt,override)
    container_type = opt[1]

    if opt[2] == :content_model_id
      container_id = self.content_publication.content_model_id
    else
      container_id = opts.send(opt[2])
    end

    content_type  = ContentType.fetch(container_type,container_id)
    if content_type
      if (override || content_type.detail_site_node_url.blank?) &&  self.page_revision.revision_container.is_a?(SiteNode)
        content_type.detail_site_node_url = self.page_revision.revision_container.node_path
      end
      if  (override || content_type.list_site_node_url.blank?) && opt[3][:list_page_id] 
        if  opt[3][:list_page_id]  == :node
          content_type.list_site_node_url = self.page_revision.revision_container.node_path
        elsif list_page_site_node = SiteNode.find_by_id(opts.send( opt[3][:list_page_id]))
          content_type.list_site_node_url = list_page_site_node.node_path
        end
      end

      content_type.save if content_type.changed?
    end
  end

  def link_canonical_meta_type!(opts,opt,override)
    container_type = opt[1]

    options = opt[2].clone

    if self.page_revision.revision_container.is_a?(SiteNode)

      # If we should only match a limited subset of 
      # content types, check if we have a category_value
      if options[:category_value]
        options[:category_value] = opts.send(options[:category_value])
        
        # If we don't have a category_value, then we don't match all
        if options[:category_value].blank?
          options.delete(:category_field)
        end
      end

      content_meta_type  = ContentMetaType.generate(self.identity_hash,container_type,options)

      content_meta_type.detail_url = self.page_revision.revision_container.node_path
      if  options[:list_page_id] && list_page_site_node = SiteNode.find_by_id(opts.send(options[:list_page_id]))
        content_meta_type.list_url = list_page_site_node.node_path 
      end

      content_meta_type.save if content_meta_type.new_record? || content_meta_type.changed?
    end
  end
  
end
