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

  def before_create
    if self.identity_hash.blank?
      self.identity_hash = DomainModel.generate_hash
    end
  end

  
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
    @language || self.page_revision.language
  end
  
  def before_create
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
  
  def editor_info
    return nil unless self.display_module
    
    disp = display_module.split("/") 
    # Get rid of any leading /
    disp.shift if disp[0] || disp[0] == ''
    
    # Get us Editor::MenuController
    className = display_module.map { |elem| elem.camelcase }.join("::") + 'Controller' 
    cls = className.constantize
    
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
  
end
