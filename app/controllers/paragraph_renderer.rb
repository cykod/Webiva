# Copyright (C) 2009 Pascal Rettig.

require 'radius'
require 'erb'

class ParagraphRenderer < ParagraphFeature

  include EndUserTable::Controller

  class ParagraphRedirect #:nodoc:all
      attr_accessor :paction
      attr_accessor :args
      attr_accessor :user_level
      attr_accessor :user_value

      def initialize(args)
        @args = args
      end
    end
  
  class ParagraphOutput #:nodoc:all
    def initialize(rnd,args)
      @rnd = rnd
      @render_args = args
    
      @includes = {}
    end
    attr_reader :rnd
    attr_reader :render_args
    attr_accessor :includes
    attr_accessor :page_connections 
    attr_accessor :page_title
    attr_accessor :paction
    attr_accessor :paction_data
    attr_accessor :content_nodes
    attr_accessor :paragraph_id
    attr_accessor :user_level
    attr_accessor :user_value

    def method_missing(method,args)
      @rnd.send(method)
    end
  end
  
  class ParagraphData #:nodoc:all
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
  
  class CachedOutput #:nodoc:all
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
  
  def instance_variable_hash #:nodoc:
    data = {}
    self.instance_variables.each { |var| data[var[1..-1].to_sym] = self.instance_variable_get(var) }
    data
  end
  
  def self.features(feature_name)#:nodoc:
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
  
  
  def self.template_root  #:nodoc:
    :editor 
  end
  
  def self.module_renderer  #:nodoc:
    sing = class << self; self; end
    sing.send :define_method, :template_root do 
      :component
    end
  end
  
  # Adds a paragraph to the renderer
  # 
  # === Available Opts
  # [:cache] 
  #    Set to true is this paragraph can be cached
  # [:ajax]
  #    Allow this paragraph to accept ajax call
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
  
  # Set a page connection of a given name
  def set_page_connection(connection_name,connection_value)
    @page_connections[paragraph.identity_hash] ||= {}
    @page_connections[paragraph.identity_hash][connection_name] = connection_value
  end 

  # Set multiple page connections of the form :name => value
  def set_page_connections(cons)
    cons.each do |key,val|
      set_page_connection(key,val)
    end
  end 

  def elevate_user_level(user, user_level)
    user.elevate_user_level(user_level) if user && user.id
    @paragraph_user_level = user_level
  end

  def unsubscribe_user(user)
    user.unsubscribe if user && user.id
    @paragraph_user_level = user_level
  end

  def set_user_value(user, val)
    user.update_user_value(val) if user && user.id
    @paragraph_user_value ||= 0.0
    @paragraph_user_value += val.to_f
  end

  attr_reader :user_class
  attr_reader :language
  attr_reader :controller
  attr_reader :opts

  def initialize(user_class,ctrl,para,site_node,revision,opts = {}) #:nodoc:
    @user_class = user_class
    @language = opts[:language]
    @preview_mode = opts[:preview]
    @controller = ctrl
    @site_node = site_node
    @revision = revision
    @para = para
    @opts = opts 

    @includes = {}
    @page_connections = {}
    @paction = nil
    @paction_data = nil
    @page_title = nil
  end
  
  # Return a dummy renderer of this class
  #
  # This can be used to create a renderer for testing or other purposes
  # when you aren't inside of a normal page view
  def self.dummy_renderer(ctrl=nil)
      self.new(UserClass.get_class('domain_user'),ctrl || ApplicationController.new,PageParagraph.new,SiteNode.new,PageRevision.new)
  end
  
  def self.document_feature(name,data={},controller=nil,publication=nil) #:nodoc:
    rnd = self.dummy_renderer(controller)
    rnd.set_documentation(true)
    if publication
      rnd.send("#{publication.feature_method_name}_feature",publication,data)
    else
      rnd.send(name,data)
    end
  end


  class CaptureDataException < Exception #:nodoc:
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
    
  
  # Is this an ajax call to the paragraph
  def ajax?
    @opts[:ajax]
  end
  
  
  # The path of the current page
  def page_path
    @opts[:page_path] || @site_node.node_path
  end
  
  # Are we currently in the page editor
  def editor?
    @opts[:editor] ? true : false
  end 
  
  # return the current paragraph this renderer is rendering
  def paragraph
    @para
  end
  
  # return an instance of of the options for the current paragraph
  def paragraph_options(paragraph_name)
  
    options_class = self.class.to_s.gsub(/Renderer$/,"Controller") + "::" + paragraph_name.to_s.camelcase + "Options"
    options_class.constantize.new(@para.data)
  end
  
  # return the current site node this renderer is rendering
  def site_node
    unless !@site_node || @site_node.is_a?(SiteNode)
      @site_node= SiteNode.find_by_id(@site_node.id)
    end
    @site_node
  
  end
  
  # return the current revision
  def revision
    unless !@revision || @revision.is_a?(PageRevision)
      @revision = PageRevision.find_by_id(@revision.id)
    end
    @revision
  end

  
  # Has this paragraph already been rendered
  def paragraph_rendered?
    @paragraph_output ? true : false
  end

  # Set the title for the page, can set specific categories as well
  def set_title(title,category = 'default')
    @page_title ||= {}
    @page_title[category] = title
  end

  attr_reader :content_object_list

  # Sets a content node associated with this paragraph, 
  # used by the editor to display edit links
  def set_content_node(obj)
    @content_node_list ||= []
    if obj.is_a?(Fixnum)
      @content_node_list << obj
    elsif obj.is_a?(ContentNode)
      @content_node_list << obj.id
    elsif obj.is_a?(DomainModel)
      @content_node_list << obj.content_node.id
    elsif obj.is_a?(Array)
      cn = ContentNode.fetch(obj[0],obj[1])
      @content_node_list << cn.id if cn
    end
  end
  
  # Returns the url for the current page (including page connections)
  def paragraph_page_url
    if editor?
      site_node.node_path
    else
      request.request_uri.split('?')[0]
    end
  end

  # Redirects a to different page
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
  
  # This is the equivalent of Controller#render except it renders an individual
  # paragraph. 
  # 
  # render_paragraph accepts an args hash similar to render
  #
  # Examples:
  #
  #    # renders "Paragraph Details"
  #    render_paragraph :text => 'Paragraph Details'
  #
  #    # renders  "hello, hello, hello, again"
  #    render_paragraph :inline => "<%= 'hello, ' * 3 + 'again' %>"
  #
  #    # renders the feature named :blog_page using instance variables for the data hash
  #    render_paragraph :feature => :blog_page
  #
  #    # renders the partial named passing the requested locals (not that you need to provide a full view path)
  #    render_paragraph :partial => '/blog/page/details', :locals => { :post => @post } 
  #
  #    # renders the rjs template named passing the requested locals (not that you need to provide a full view path)
  #    render_paragraph :rjs => '/blog/page/update', :locals => { :post => @post } 
  #
  #    # renders the rjs template named passing the requested locals (not that you need to provide a full view path)
  #    # however this will actually be called against the containing document (in the case of an iframe)
  #    render_paragraph :parent_rjs => '/blog/page/update_parent', :locals => { :post => @post } 
  #
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
  
  # This is the equivalent of Controller#send_data except it can be called in a
  # renderer.
  #
  # If a renderer calls data_paragraph, it supercedes anything else on the page
  # and any other paragraphs that have not been compiled will not be rendered
  #
  # Files are sent using send_file or x_send_file if it is enabled and installed
  # in defaults
  #
  # Examples:
  #
  #    # renders the specified text (nothing else will be rendered)
  #    data_paragraph :text => '{ "test" : "value" }'
  #
  #    # renders an image directly from data
  #    data_paragraph :data => @file.image_data, :type => 'image/jpeg'
  #
  #    # renders the specified file (the full path of the file must be specified
  #    data_paragraph :file => "#{RAILS_ROOT}/tmp/widgets/something.gif"
  #
  #    # renders the specified domain file 
  #    data_paragraph :domain_file => @domain_file
  #
  def data_paragraph(args)
    if @paragraph_output
      raise 'Only 1 paragraph output function can be called per paragraph'
    end
    @paragraph_output = ParagraphData.new(self,args)
  end
  
  
  def redirect(args) #:nodoc:
    raise 'Use redirect_paragraph to redirect a paragraph'
  end
  
  def render(args) #:nodoc:
    raise 'Use render_paragraph to render a paragraph'
  end
  
  # Links an action to this request. See EndUserAction for more information on user actions.
  #
  # Example:
  #
  #    paragraph_action(myself.action('/action/path'))
  #
  def paragraph_action(pact,pact_data=nil)
    if pact.is_a?(EndUserAction)
      @paction = pact
    else
      # raise "Deprecated paragraph action call.."
    end
  end 
  
  def html_set_attribute(part, value={})
    @includes[part.to_sym] ||= {}
    @includes[part.to_sym].merge! value
  end

  def html_include(part, value=[])
    @includes[part.to_sym] ||= []
    value = [value] unless value.is_a?(Array)
    @includes[part.to_sym] += value
  end

   # Includes the specified javascript file when the page is rendered
  # uses the standard rails javascript_include_tag syntax
  def require_js(js)
    @includes[:js] ||= []
    if js.is_a?(Array)
      js.each { |fl| require_js(fl) }
    else
      js.downcase!
      js += ".js" unless js =~ /^https?:\/\// || js[-3..-1] == '.js'
      @includes[:js] << js
    end
  end
  
  # Requires all the standard ajax javascript files
  def require_ajax_js
    require_js('prototype.js')
    require_js('effects.js')
    require_js('builder')
    require_js('redbox')
    require_css('redbox')        
    require_js('user_application.js')
  end
  
  # returns a url that can be used to make javascript calls directly back to this paragraph
  # 
  # :ajax => true must be enabled on the call to ParagraphRenderer#self.paragraph
  def ajax_url(opts={})
    opts = opts.merge(:site_node => self.paragraph.page_revision.revision_container_id, 
                         :page_revision => self.paragraph.page_revision.id,
                         :paragraph => self.paragraph.id)
    paragraph_action_url(opts)
  end

  def insert_page_connection_hash!(output,replacement)
    output.gsub!(replacement,page_connection_hash)
  end

  # Returns a hash of the page connections and stores them safely in the
  # session for an ajax call
  def page_connection_hash
    return @page_connection_hash if @page_connection_hash
    conns = self.paragraph.page_connections || {}
    output_hsh = {}
    conns.each do |key,val|
      output_hsh[key] = page_connection_hash_helper(val)
    end
    hash_hash = DomainModel.hash_hash(output_hsh)
    session[:page_connection_hash] ||= {}
    session[:page_connection_hash][paragraph.id.to_s + "_" + hash_hash] = output_hsh

    @page_connection_hash = hash_hash
  end

  def set_page_connection_hash(conns) #:nodoc:
    output_hash = {}
    conns.each do |key,val|
      output_hash[key] = set_page_connection_hash_helper(val)
    end
    self.paragraph.page_connections = output_hash
  end

  def page_connection_hash_helper(val) #:nodoc:
    if val.is_a?(Array)
       val.map { |sval| page_connection_hash_helper(sval) }
    elsif val.kind_of?(Hash)
       output = {}
       val.each { |key,sval| output[key] = page_connection_hash_helper(sval) }
       output
    elsif val.kind_of?(DomainModel)
      { :domain_model_hash => true, :cls => val.class.to_s, :id => val.id  }
    elsif val.kind_of?(HashModel)
      { :hash_model_hash => true, :cls => val.class.to_s, :attr => val.to_hash }
    else
      val
    end
  end


  def set_page_connection_hash_helper(val) # :nodoc:
    if val.is_a?(Hash)
      if val[:domain_model_hash]
        if val[:cls]=='EndUser' && val[:id].blank?
          myself
        else
          val[:cls].constantize.find(val[:id])
        end
      elsif val[:hash_model_hash]
        val[:cls].constantize.new(val[:attr])
      else
        output = {}
        val.each { |key,sval| output[key] = set_page_connection_hash_helper(sval) }
       output
      end
    elsif val.is_a?(Array)
      val.map { |sval| set_page_connection_hash_helper(sval) }
    else
      val
    end
  end

 
  # Includes the specified css file when the page is rendered
  # uses the standard rails stylesheet_link_tag syntax
  def require_css(css)
    @includes[:css] ||= []
    if css.is_a?(Array)
      @includes[:css] += css
    else
      @includes[:css] << css
    end
  end
   
  # Includes some custom html code in the head of the document
  # if you want to use javascript you must explicitly include the <script>..</script> tags
  def include_in_head(html)
    @includes[:head_html] ||= []
    @includes[:head_html] << html
  end

  def form_authenticity_token #:nodoc:
    @controller.send(:form_authenticity_token)
  end
  
  def method_missing(method,*args) #:nodoc:
    if args.length > 0
      @controller.send(method,*args)
    else
      @controller.send(method)
    end
  end
  
  # Return state of the renderer, include current user, and controller, allowing for override
  def renderer_state(override={ })
    conn_type,conn_id = page_connection
    {:user => myself, :renderer => self, :controller => @controller, :page_connection => conn_id }.merge(override)
  end
  
  def output #:nodoc:
    if @paragraph_output.is_a?(ParagraphOutput) || @paragraph_output.is_a?(CachedOutput)
      @paragraph_output.includes = @includes
      @paragraph_output.page_connections = @page_connections
      @paragraph_output.paction = @paction
      @paragraph_output.page_title = @page_title
      @paragraph_output.content_nodes = @content_node_list
      @paragraph_output.user_level = @paragraph_user_level if @paragraph_output.is_a?(ParagraphOutput)
      @paragraph_output.user_value = @paragraph_user_value if @paragraph_output.is_a?(ParagraphOutput)
    elsif @paragraph_output.is_a?(ParagraphRedirect)
      @paragraph_output.paction = @paction
      @paragraph_output.user_level = @paragraph_user_level
      @paragraph_output.user_value = @paragraph_user_value
    end
    @paragraph_output 
  end
  
  # Override the current feature to the one specified by id or object
  def set_feature(feature)
    if(feature && feature != 0)
      feature = SiteFeature.find_by_id(feature) if feature.is_a?(Integer)
      @para.site_feature = feature if feature
    end
  end
  
=begin rdoc
This is a convenience method that allows you to easily cache the output of 
a renderer (and have that cache automatically invalidated when necessary)
If accepts a block that yields a DefaultsHashObject and returns that
object. The first time renderer_cache is called, the block will be executed
while on subsequent calls (if the cache is still valid) the block will not be
executed but the result will be pulled directly from the cache.

=== Warning
The cache expects only simple types: Strings, Hashes, Arrays, Times, Numbers, etc to be
stored in the cache. Any complex objects stored in the cache may result in a 
errors when they are unmarshalled. Don't Do it. Really -- just don't.
  
=== Simplest Usage
  
The simplest usage of renderer_cache is with no arguments, in which case the cache
will be stored until the paragraph is resaved:
  
   result = renderer_cache do |cache|
      ...
      cache[:data1] = "Piece of data"
      cache[:data2] = "Other piece of data"
   end

   set_title(result.data2)
   render_paragraph :text => result.data1
 
Notice to set items on the cache object you should use the associate array syntax, 
but to pull them out you can use standard dot notation.

=== Using with cached content

If you are display a list or an individual DomainModel that has cached content set
( see ModelExtension::ContentCacheExtension ). You can pass an indvidiual object, an array of a [ class_name, item_id ] , 
or the class to renderer_cache. This will ensure that the cache is automatically invalidated 
when the object is saved (or in the case of passing the class any object is saved)

Lets take an example of the Blog::BlogPost class:

   @blog_post = Blog::BlogPost.find_by_id(17)

   # On both cases below, the cache will be invalidated if blog post w/ id=17 is updated in the database
   renderer_cache(@blog_post) { |cache| ... }                                              
   renderer_cache(["Blog::BlogPost",17]) { |cache| ... }
  
   # In this case the cache will be invalidated if any blog post is saved
   renderer_cache(Blog::BlogPost) { |cache| ... }                                            

=== Using the display string

By default the renderer_cache is unique to the paragraph, so you don't necessarily need to 
pass a display_string if the same paragraph is only going to render a single view of the passed object.
However, if the paragraph needs to render multiple views of the same data, such as the a blog 
list paragraph that displays multiple pages.

For example:
   
   page = (params[:page]||1).to_i 
   page = 1 if page <= 0
   
   # Each page will be cached separately
   renderer_cache(Blog::BlogPost,page) { |cache| ... }

=== Included css and javascript

Renderer cached will automatically cache any javascript and css includes 
(i.e. require_css / require_js ) that have been included by the end of the
block, so you can put your includes inside of your renderer_cache block 
(or even inside of the feature if necessary) and they will get pulled in
correctly


=== Expiration

The only option current supported in the options hash is :expires which should be
an integer representing the number of seconds to keep the element in the cache.

=end
  def renderer_cache(obj=nil,display_string=nil,options={ },&block)
    expiration = options[:expires] || 0
    display_string = "#{paragraph.id}_#{paragraph.language}_#{display_string}"
    result = nil

    unless editor? || options[:skip] || @preview_mode
      if obj.nil?
        paragraph_cache_id = paragraph.id == -1 ? "Mod#{site_node.id}" : paragraph.id.to_s
        result = DataCache.get_content("Paragraph",paragraph_cache_id,display_string)
      elsif obj.is_a?(Array)
        cls = obj[0].is_a?(String) ? obj[0].constantize : obj[0]
        result = cls.cache_fetch(display_string,obj[1])
      elsif obj.is_a?(ActiveRecord::Base)
        result = obj.cache_fetch(display_string)
      else
        result = obj.cache_fetch_list(display_string)
      end
    end
    
    if result
      @includes = result[:cached_includes].clone
      return DefaultsHashObject.new(result)
    else
      result = DefaultsHashObject.new(result)
      yield result

      output = result.to_hash
      output[:cached_includes] = @includes.clone

      unless editor? || options[:skip] || @preview_mode
        if obj.nil?
          DataCache.put_content("Paragraph",paragraph_cache_id,display_string,output,expiration)
        elsif obj.is_a?(Array)
          cls.cache_put(display_string,output,obj[1],expiration)
        elsif obj.is_a?(ActiveRecord::Base)
          obj.cache_put(display_string,output,nil,expiration)
        else
          obj.cache_put_list(display_string,output,expiration)
        end
      end
      
      return result
    end

  end
  

  # Fetch a element from the remote cache
  def delayed_cache_fetch(obj,method,args={},display_string=nil,options={ })
    expiration = options[:expires] || 120 # Default to two minutes
    display_string = "#{paragraph.id}_#{display_string}"
    result = nil
 
    result, expired_at = DataCache.get_remote("Paragraph",paragraph.id.to_s,display_string)
    now = Time.now
    if result && expired_at && expired_at > now
      return DefaultsHashObject.new(result)
    end

    remote_args = args.merge( :remote_type => 'Paragraph', :remote_target => paragraph.id.to_s, :display_string => display_string, :expiration => expiration )

    if editor?
      logger.warn("Running Editor Delayed worker: #{display_string}")
      result = obj.send(method, remote_args)
      if result
        return DefaultsHashObject.new(result)
      else
        return nil
      end
    end

    # if we don't have an expired or we are expired and not in the editor
    # kick of the worker and put the current results in the cache to be updated
    if !result || !expiration || expired_at <= now
      DataCache.put_remote("Paragraph",paragraph.id.to_s,display_string,[ result, now + expiration.to_i.seconds ])
      logger.warn("Running Delayed worker: #{display_string}")
      if obj.is_a?(Class)
        DomainModel.run_worker(obj.to_s,nil,method,remote_args)
      else
        DomainModel.run_worker(obj.class.to_s,obj.id,method,remote_args)
      end
    end
    
    return result if result
  end

  
  def self.get_editor_features #:nodoc:
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
  
  def self.get_component_features #:nodoc:
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
  
  def debug_print(obj) #:nodoc:
    render_paragraph :inline => "<%= debug obj %>", :locals => {:obj => obj }  
    return
  end
  
  protected
  #  All the paragraph_render tag helper are deprecated


  def define_position_tags(c,prefix=nil) #:nodoc:
    c.define_position_tags(prefix)
  end
  
  def define_block_value_tag(c,tag_name,&block) #:nodoc:
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

  def define_value_tag(c) #:nodoc:
    c.define_tag 'value' do |tag|
      tag.locals.value
    end
  end
        
  def define_value_tags(c,obj,tags,&block) #:nodoc:
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
  
  def define_no_value_tags(c,obj,tags) #:nodoc:
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
  def define_image_tag(c,tag_name,local_obj,attribute=nil,&block) #:nodoc:
    c.define_image_tag(tag_name,local_obj,attribute,&block)
  end     

  def define_submit_tag(c,tag_name,options = {:default => 'Submit'.t }) #:nodoc:

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

 
  def run_triggered_actions(trigger_name, data, user=nil)
    user ||= myself
    paragraph.run_triggered_actions(data, trigger_name, user, session)
  end
 
end
