# Copyright (C) 2009 Pascal Rettig.

require 'radius'
require 'erb'

class ParagraphRenderer < ParagraphFeature

  
  class ParagraphRedirect
      attr_accessor :paction
      attr_accessor :args
      def initialize(args)
        @args = args
      end
    end
  
  class ParagraphOutput
    def initialize(rnd,args)
      @rnd = rnd
      @render_args = args
    
      @includes= {}
    end
    attr_reader :rnd
    attr_reader :render_args
    attr_accessor :includes
    attr_accessor :page_connections 
    attr_accessor :page_title
    attr_accessor :paction
    attr_accessor :paction_data
    
    def method_missing(method,args)
      @rnd.send(method)
    end
  end
  
  class ParagraphData
    def initialize(rnd,args)
      @rnd = rnd
      @render_args = args
    
    end
    attr_reader :render_args
    attr_accessor :page_connections 
    attr_accessor :paction
    attr_accessor :paction_data
    
    
    
    def method_missing(method,args)
      @rnd.send(method)
    end
  end
  
  class CachedOutput
    def initialize(output,includes,page_connections,page_title=nil)
      @output = output
      @includes = includes
      @page_connections = page_connections
      @page_title = page_title
    end
    
    attr_accessor :output
    attr_accessor :includes
    attr_accessor :page_connections
    attr_accessor :page_title
    
    def paction
      nil
    end
    
    def paction_data
      nil
    end
  end
  
  def instance_variable_hash
    data = {}
    self.instance_variables.each { |var| data[var[1..-1].to_sym] = self.instance_variable_get(var) }
    data
  end
  
  def self.features(feature_name)
    cls_name =  feature_name.to_s.classify
    cls = cls_name.constantize

    
    cls.available_features.each do |feat|
      method_definition = <<-METHOD
      def #{feat}_feature(*data)
        
        cls = #{cls_name}.new(@para,self)
        cls.set_documentation(self.documentation)
        if data.length == 0
          raise ParagraphRenderer::CaptureDataException.new(instance_variable_hash) if capture_data
          cls.#{feat}_feature(instance_variable_hash)
        else
          raise ParagraphRenderer::CaptureDataException.new(*data) if capture_data
          cls.#{feat}_feature(*data)
        end
      end
      METHOD
      
      
      
      self.class_eval method_definition, __FILE__,__LINE__
    end
    
  end
  
  
  def self.template_root
    :editor
  end
  
  def self.module_renderer
    sing = class << self; self; end
    sing.send :define_method, :template_root do 
      :component
    end
  end
  
 
  def self.paragraph(type,opts = {})
    sing = class << self; self; end
    opts[:cache] ||= false
    sing.send :define_method, "paragraph_info_#{type.to_s}" do
      opts
    end
  end
  
  # Return the page connection of a given name
  # if not found, check if it's the default connection
  # and if it is return the path parameters
  def page_connection(input_key = :input)
    connection = @para.page_connection(input_key.to_sym)
    
    unless connection
      info = self.class.send('paragraph_info_' + @para.display_type)
      if info[:default_connection]
        connection = [ info[:default_connection], (params[:path]||[])[0] ]
      end
    end
    connection
  end
  
  def set_page_connection(connection_name,connection_value)
    @page_connections[paragraph.identity_hash] ||= {}
    @page_connections[paragraph.identity_hash][connection_name] = connection_value
  end 
  
  attr_reader :user_class
  attr_reader :language
  attr_reader :controller
  attr_reader :opts

  def initialize(user_class,ctrl,para,site_node,revision,opts = {})
    @user_class = user_class
    @language = opts[:language]
    @controller = ctrl
    @site_node = site_node
    @revision = revision
    @para = para
    @opts = opts 
    
    @js_includes = []
    @css_includes = []
    @head_html = []
    @page_connections = {}
    @paction = nil
    @paction_data = nil
    @page_title = nil
  end
  
  def self.dummy_renderer
      self.new(UserClass.get_class('domain_user'),ApplicationController.new,PageParagraph.new,SiteNode.new,PageRevision.new)
  end
  
  def self.document_feature(name,data={},publication=nil)
    rnd = self.dummy_renderer
    rnd.set_documentation(true)
    if publication
      rnd.send("#{publication.feature_method_name}_feature",publication,data)
    else
      rnd.send(name,data)
    end
  end


  class CaptureDataException < Exception
    def initialize(pub,data=nil)
      if data
        @data = data
      else
        @data = pub
      end
    end

    attr_reader :data     
  end

  attr_accessor :capture_data
    
  
  def ajax?
    @opts[:ajax]
  end
  
  
  def page_path
    @opts[:page_path] || @site_node.node_path
  end
  
  def editor?
    @opts[:editor] ? true : false
  end 
  
  def paragraph
    @para
  end
  
  def paragraph_options(paragraph_name)
  
    options_class = self.class.to_s.gsub(/Renderer$/,"Controller") + "::" + paragraph_name.to_s.camelcase + "Options"
    options_class.constantize.new(@para.data)
  end
  
  def site_node
    unless !@site_node || @site_node.is_a?(SiteNode)
      @site_node= SiteNode.find_by_id(@site_node.id)
    end
    @site_node
  
  end
  
  def revision
    unless !@revision || @revision.is_a?(PageRevision)
      @revision = PageRevision.find_by_id(@revision.id)
    end
    @revision
  end

  
  

  def paragraph_rendered?
    @paragraph_output ? true : false
  end

  def set_title(title,category = 'default')
    @page_title ||= {}
    @page_title[category] = title
  end
  
  def paragraph_page_url
    if editor?
      site_node.node_path
    else
      request.request_uri.split('?')[0]
    end
  end

  def redirect_paragraph(args)
    if args == :page
          args = paragraph_page_url
    end
    if args.is_a?(Hash) && args[:site_node]
      node = SiteNode.find_by_id(args[:site_node])
      if node
        args = node.node_path
      else
        args = paragraph_page_url
      end
    end
    if @paragraph_output
      raise 'Only 1 paragraph output function can be called per paragraph'
    end
    @paragraph_output = ParagraphRedirect.new(args)
  end
  
  def render_paragraph(args)
    if @paragraph_output
      raise 'Only 1 paragraph output function can be called per paragraph'
    end
    if args[:feature]
      feature = args.delete(:feature)
      raise "Undefined feature: #{feature}" unless self.respond_to?("#{feature}_feature") 
      args[:text] = self.send("#{feature}_feature") 
    end
    if args[:partial] && !args[:locals]
      args[:locals] = instance_variable_hash
    end
    @paragraph_output = ParagraphOutput.new(self,args)
  end
  
  def data_paragraph(args)
    if @paragraph_output
      raise 'Only 1 paragraph output function can be called per paragraph'
    end
    @paragraph_output = ParagraphData.new(self,args)
  end
  
  def redirect(args)
    raise 'Use redirect_paragraph to redirect a paragraph'
  end
  
  def render(args)
    raise 'Use render_paragraph to render a paragraph'
  end
  
  def paragraph_action(pact,pact_data=nil)
    if pact.is_a?(EndUserAction)
      @paction = pact
    else
      # raise "Deprecated paragraph action call.."
    end
  end 
  
  def require_js(js)
    if js.is_a?(Array)
      js.each { |fl| require_js(fl) }
    else
      js.downcase!
      js += ".js" unless js[-3..-1] == '.js'
      @js_includes << js
    end
  end
  
  def require_ajax_js
    require_js('prototype.js')
    require_js('effects.js')
    require_js('builder')
    require_js('redbox')
    require_css('redbox')        
    require_js('user_application.js')
  end
  
 def ajax_url(opts={})
    opts = opts.merge(:site_node => self.paragraph.page_revision.revision_container_id, 
                         :page_revision => self.paragraph.page_revision.id,
                         :paragraph => self.paragraph.id)
    paragraph_action_url(opts)
  end    
 
 def require_css(css)
   if css.is_a?(Array)
     @css_includes += css
   else
     @css_includes << css
   end
 end
   
  def include_in_head(html)
    @head_html << html
  end

  def form_authenticity_token
    @controller.send(:form_authenticity_token)
  end
  
  def method_missing(method,*args)
    if args.length > 0
      @controller.send(method,*args)
    else
      @controller.send(method)
    end
  end
  
  def renderer_state
    {:user => myself, :renderer => self, :controller => @controller }
  end
  
  def output
    if @paragraph_output.is_a?(ParagraphOutput) || @paragraph_output.is_a?(CachedOutput)
      @paragraph_output.includes[:css] = @css_includes if @css_includes.length > 0
      @paragraph_output.includes[:js] = @js_includes if @js_includes.length > 0
      @paragraph_output.includes[:head_html] = @head_html if @head_html.length > 0
      @paragraph_output.page_connections = @page_connections
      @paragraph_output.paction = @paction
      @paragraph_output.page_title = @page_title
    elsif @paragraph_output.is_a?(ParagraphRedirect)
      @paragraph_output.paction = @paction
    end
    @paragraph_output 
  end
  
  def set_feature(feature)
    if(feature && feature != 0)
      feature = SiteFeature.find_by_id(feature) if feature.is_a?(Integer)
      @para.site_feature = feature if feature
    end
  end
  
 
  
  def self.get_editor_features
    # Find all the renderers in the 'editors' subdirectory,
    # get the class constant
    # Call the class methods to get the title,
    # and the 
    
    feature_list = []
    Dir.glob("#{RAILS_ROOT}/app/controllers/editor/[a-z0-9\-_]*_renderer.rb") do |file|
      if file =~ /\/([a-z0-9\-_]+)_renderer.rb$/
        renderer_name = $1
        cls_name = "Editor::#{renderer_name.camelcase}Renderer"
        cls = cls_name.constantize
        features = cls.available_features
        features.each do |feature|
          feature_list << [feature.to_s.humanize.capitalize,feature.to_s,cls_name ]
        end
      end
    end
    Dir.glob("#{RAILS_ROOT}/app/controllers/editor/[a-z0-9\-_]*_feature.rb") do |file|
      if file =~ /\/([a-z0-9\-_]+)_feature.rb$/
        renderer_name = $1
        cls_name = "Editor::#{renderer_name.camelcase}Feature"
        cls = cls_name.constantize
        features = cls.available_features
        features.each do |feature|
          feature_list << [feature.to_s.humanize.capitalize,feature.to_s,cls_name ]
        end
      end
    end    
    feature_list
  end
  
  def self.get_component_features
   feature_list = []
   
   SiteModule.enabled_modules_info.each do |mod|
      mod.get_renderers.each do |cls|
        features = cls.available_features
        features.each do |feature|
          feature_list << [feature.to_s.humanize.capitalize,feature.to_s,cls.to_s ]
        end
      end
      mod.get_features.each do |cls|
        features = cls.available_features
        features.each do |feature|
          feature_list << [feature.to_s.humanize.capitalize,feature.to_s,cls.to_s ]
        end
      end
   end
   feature_list
  end   
  
  def debug_print(obj)
    render_paragraph :inline => "<%= debug obj %>", :locals => {:obj => obj }  
    return
  end
  
  protected
  # Helper for feature parsing
  def define_position_tags(c,prefix=nil)
    c.define_position_tags(prefix)
  end
  
  def define_block_value_tag(c,tag_name,&block)
    c.define_tag tag_name do |tag|
      val = block.call
      if tag.single?
        val
      else
        if val.to_s.empty? 
          nil
        else
          tag.locals.value = val
          tag.expand
        end
      end
    end

    c.define_tag "#{tag_name}:value" do |tag|
      tag.locals.value
    end

    c.define_tag "no_#{tag_name}" do |tag|
      val = block.call
      val.to_s.empty?  ? tag.expand : nil
    end
  end

  def define_value_tag(c) 
    c.define_tag 'value' do |tag|
      tag.locals.value
    end
  end
        
  def define_value_tags(c,obj,tags,&block)
    block_func = block_given?
    tags.each do |tag_name| 
      c.define_tag tag_name do |tag|
        val = obj.send(tag_name)
        if block_func
          format_val = block.call(val)
        else
          format_val  = html_escape(val)
        end
        if tag.single?
          format_val
        else
          if val.to_s.empty?
            nil
          else
            tag.locals.value = format_val
            tag.expand
          end
        end
      end
    end
    
  end
  
  def define_no_value_tags(c,obj,tags)
    tags.each do |tag_name|
      c.define_tag "no_" + tag_name do |tag|
        val = obj.send(tag_name)
        if val.to_s.strip.empty?
         tag.expand
        else
          nil
        end
      end
    end
  end
  
  # helper for displaying images in a renderer
  def define_image_tag(c,tag_name,local_obj,attribute=nil,&block)
    c.define_image_tag(tag_name,local_obj,attribute,&block)
  end     

  def define_submit_tag(c,tag_name,options = {:default => 'Submit'.t })

    c.define_tag tag_name do |tag|
      output =''
      if tag.single?
        txt = tag.attr['value'] || options[:default]
        output ="<input type='submit' name='button' value='#{vh txt}'/>"
      else
        if tag.attr['type'] == 'image'
          output = "<input type='image' src='#{vh tag.expand}' align='absmiddle'/>"
        else
          output = "<input type='submit' name='button' value='#{vh tag.expand}'/>"
        end
      end
      if(options.has_key?(:form))
        if !options[:form]
          nil
        else
          "<form action='#{options[:form]}' method='#{options[:method]||'get'}'>" + output + "</form>"
        end
      else
        output
      end
    end
  end



  # Helper for displaying pages in a renderer
  def define_pages_tag(c,path,page,pages,options = {}) 
    c.define_pages_tag('pages',path,page,pages,options = {})
  end
  
 

 
end
