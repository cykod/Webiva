# Copyright (C) 2009 Pascal Rettig.

require "mime/types"
require 'digest/sha1'

=begin rdoc
SiteNodeEngine is the class that is responsible for assembling the various paragraphs and frameworks
and doing what's necessary to render the page.

Most of the time it's not a class that you'll have to use, but as it forms the backbone of Webiva,
it's important to know a little bit about it:

At the most basic level, if you need to render a specific site node, you could do something like the following:

   begin  
     @page = SiteNode.find(@site_node_id)
     engine = SiteNodeEngine.new(@page,:display => session[:cms_language], :path => path_args)

     # Call engine.run with the controller you're in and the current EndUser object
     @output = engine.run(self,myself)
   # catch a couple of exceptions and render a 404
   rescue ActiveRecord::RecordNotFound, SiteNodeEngine::NoActiveVersionException, SiteNodeEngine::MissingPageException => e
     render :text => 'Page not found', :status => 404
     return
   end

   if @output.redirect?
     redirect_to(@output.redirect, :status => 301)
   elsif @output.document?
     handle_document_node(@output,@page)
   elsif @output.page?
     render :text => render_output(@page,@output)
   end 

The last render comment would just render the body of the page (without a <html> or <head> tag, 
see layouts/page.rhtml for what's necessary to render a full html page.

If you'd like to use SiteNodeEngine but generate your own body in a standard-ish rails controller
you can subclass ModuleAppController and add whatever routes you need to routes.rb. If create a site
tree that mimics your routes and a "Module application" paragraph your application will rendered on 
whatever pages are necessary.

=end
class SiteNodeEngine

  # These methods are include in the ModuleAppController and aid
  # in rendering site nodes
  module Controller

    # Return a page given an array of page arguments and a site_version_id
    def find_page_from_path(path_elems,site_version_id)
      path_elems = path_elems.clone
      path_args = []
      page = nil
      search_path = "/" + path_elems.join("/")
      loop do
        page = SiteNode.find(:first,
                            :conditions => ['node_path = ? AND node_type IN ("P","M","D","J") AND site_version_id=?',search_path,site_version_id],
                            :order => 'position DESC')
        break if page || path_elems.length == 0
        
        path_args.unshift(path_elems.slice!(-1))
        search_path = "/" + path_elems.join('/')
      end

      return page,path_args
    end  

    # Correctly render a document node which is the result of a rendering a page where
    # a paragraph calls ParagraphRenderer#data_paragraph or the rendering of a DocumentNode
    def handle_document_node(output,page)
    
      # if we have data, just output the data
      if output.text?
        render output.options
        return
      elsif output.data?
        send_data(output.data,output.options)
        return
      # if we have just a filename, assume its an inline file like an image
      elsif output.file?
        filename = output.file
        mime_types =  MIME::Types.type_for(filename) 
        if USE_X_SEND_FILE
        	x_send_file(filename,
                  :type => mime_types[0] ? mime_types[0].to_s : 'text/plain',
                  :disposition => 'inline'
                  )    
        else
        	send_file(filename,
                  :type => mime_types[0] ? mime_types[0].to_s : 'text/plain',
                  :disposition => 'inline'
                  )    
        end
        return
      # If we have a domain file, send that
      elsif output.domain_file?
	domain_file = output.domain_file
        filename = domain_file.filename
        name = domain_file.name
      # Otherwise we have a document node (domain file), that needs to be sent
      else
        domain_file = page.domain_file
        if domain_file.folder?
          args = "/" + output.path_args.join("/").to_s.strip
          domain_file = DomainFile.find_by_file_path(domain_file.file_path + args)
          
          if domain_file
            filename = domain_file.filename
            name = domain_file.name
          else
            raise MissingPageException.new(page,@output.language)
          end
        else 
          filename = domain_file.filename
          name = page.title # domain_file.name
        end
      end
      mime_types =  MIME::Types.type_for(filename) 
      if USE_X_SEND_FILE
        x_send_file(filename,
                  :type => mime_types[0] ? mime_types[0].to_s : 'text/plain',
                  :disposition => domain_file.image? ? 'inline' : 'attachment',
                  :filename => name)    
      else
        send_file(filename,
                  :type => mime_types[0] ? mime_types[0].to_s : 'text/plain',
                  :disposition => domain_file.image? ? 'inline' : 'attachment',
                  :filename => name)    
      end
    end
    
    # Takes a paragraph and runs it through the renderer (calling the 
    # appropriate renderer method), doesn't actually render the
    # output if the paragraph is rendering a partial
    def compile_paragraph(site_node,revision,paragraph,opts={})
      # Get the type of paragraph
      paragraph = PageParagraph.thaw(paragraph) if paragraph.is_a?(Hash)
      paragraph.language = opts[:language]
      # Handle any paragraph inputs
      # return nil unless we have all the inputs we need

      return nil unless set_page_connections(paragraph,opts)
      
      opts[:language] ||= ( Locale.language ? Locale.language.code : Configuration.languages[0] )
      opts[:page_path] ||= site_node.node_path
      rendering_module = paragraph.display_module
      # We'll have something like /editor/menu
      if rendering_module
        return render_module_paragraph(site_node,revision,paragraph,opts)
      else
        display_type = paragraph.display_type
        if paragraph.display_body.blank? && paragraph.display_body == '' && !opts[:edit]
          return ParagraphRenderer::ParagraphOutput.new(self,:text => "")
        elsif opts[:edit]
          return ParagraphRenderer::ParagraphOutput.new(self,:text => "<div class='#{paragraph.display_type}_paragraph'>" +  strip_script_tags(paragraph.display) + "</div>")
        else
          return ParagraphRenderer::ParagraphOutput.new(self,:text => "<div class='#{paragraph.display_type}_paragraph'>" +  paragraph.display + "</div>")
        end
      end
    end

    def render_module_paragraph(site_node,revision,paragraph,opts)
      display_type = paragraph.display_type
      cls = paragraph.renderer
      info = paragraph.info
      output = nil
      cache_hash=''
      output = fetch_from_paragraph_cache(info,paragraph,opts) if info[:paragraph_cache] && !opts[:edit]

      return output if output # early out with cached paragraph

      rnd = cls.new(myself.user_class,self,paragraph,site_node,revision,opts)

      set_page_connection_hash(rnd,paragraph) if opts[:ajax] && params[:page_connection_hash]

      rnd.capture_data = true if  opts[:capture]
      if paragraph.site_feature_id && !opts[:edit]
        # If we're not in the editor, include the feature css
        # We have the css attribute from paragraph cached from the thaw
        if paragraph.render_css.nil? ? (paragraph.site_feature && !paragraph.site_feature.rendered_css.blank?) : paragraph.render_css
          rnd.require_css("/stylesheet/f#{paragraph.site_feature_id}.css") 
        end
      end

      ## Actually Call the method on the renderer ##
      rnd.send(display_type)

      if info[:paragraph_cache] && !opts[:edit]
        output = rnd.output
        output_hash = { :html => render_paragraph(site_node,revision,output,opts),
          :includes => output.includes,
          :page_connections => output.page_connections }
        DataCache.put_container("Paragraph","#{paragraph.display_module}:#{opts[:language]}:#{myself.user_class_id}:#{cache_hash}",output_hash)
        return ParagraphRenderer::CachedOutput.new(output_hash[:html],output_hash[:includes],output_hash[:page_connections])
      end

      # Add in the rendered css for the editor          
      editor_add_rendered_css!(rnd,paragraph) if opts[:edit]

      return rnd.output
    end

    def fetch_from_paragraph_cach(info,paragraph,opts={})
      cache_hash = cls.send(info[:paragraph_cache],paragraph,myself.user_class)
      # If this user class doesn't have a cache hash
      if cache_hash
        output_hash = DataCache.get_container("Paragraph","#{paragraph.display_module}:#{opts[:language]}:#{myself.user_class_id}:#{cache_hash}")
        output = ParagraphRenderer::CachedOutput.new(output_hash[:html],output_hash[:includes],output_hash[:page_connections]) if output_hash
      end
    end


    def set_page_connection_hash(rnd,paragraph)
      pch = (session[:page_connection_hash] || {})[paragraph.id.to_s + "_" + params[:page_connection_hash]]
      rnd.set_page_connection_hash(pch) if pch
    end
      

    def editor_add_rendered_css!(rnd,paragraph)
      if paragraph.site_feature_id && paragraph.site_feature
        rnd.output.render_args[:css] = paragraph.site_feature.rendered_css unless paragraph.site_feature.rendered_css.blank?
      end

      if rnd.output.is_a?(ParagraphRenderer::ParagraphOutput) && rnd.output.includes && rnd.output.includes[:css]
        css_files = rnd.output.includes[:css]
        rnd.output.render_args[:css] ||= ''
        css_files.each do |fl|
          begin # TODO - extract this and fix path generation
            fl += ".css" unless fl[-4..-1] == ".css"
            fl = "/stylesheets/" + fl if fl[0..0] != '/'
            css = IO.readlines(File.join(Rails.root,"public",fl)).join
            rnd.output.render_args[:css] << "\n"
            rnd.output.render_args[:css] << css
          rescue Exception => e
            # chomp
            raise e if Rails.env != 'production'
          end
        end
      end
    end

    def set_page_connections(paragraph,opts={})
      if !opts[:editor] && paragraph.connections && paragraph.connections[:inputs].is_a?(Hash)
        opts[:connections] ||= {}
        paragraph.connections[:inputs].each do |input_key,input|
          if input[0].to_s == "0"
            case input[1].to_s
            when 'page_arg_0':
                paragraph.set_page_connections(input_key =>  params[:path][0])
            when 'page_arg_1':
                paragraph.set_page_connections(input_key => params[:path][1])
            when 'page_arg_2':
                paragraph.set_page_connections(input_key => params[:path][2])
            when 'user_target':
                paragraph.set_page_connections(input_key => myself)
            when 'logged_in_target':
                paragraph.set_page_connections(input_key => myself.id ? myself : nil)
            when 'title':
                if opts[:connections][:title]
                  paragraph.set_page_connections(input_key =>  opts[:connections][:title])
                elsif !opts[:edit]
                  return nil
                end
            when 'title_str':
                if opts[:connections][:title_str]
                  paragraph.set_page_connections(input_key => opts[:connections][:title_str] )
                elsif !opts[:edit]
                  return nil
                end
            end
          else
            if opts[:connections][input[0].to_s] && opts[:connections][input[0].to_s].has_key?(input[1].to_sym)
              paragraph.set_page_connections(input_key.to_sym => opts[:connections][input[0].to_s][input[1].to_sym])
            elsif !opts[:edit] && !opts[:ajax]
              return nil
              #paragraph.info[:cache] = false # We might not have the right connections if we are in the pre-compile step
            end
          end
        end
      end
      true
    end

    def strip_script_tags(txt)
      txt.gsub(/\<script.*?\<\/script\>/im,'')
    end
    
    # Renders a paragraph, returns a string containing the outputed html
    # will compile the paragraph if necessary
    def render_paragraph(site_node,revision,paragraph,opts = {})
      opts[:edit] = true if opts[:editor]
      if(paragraph.is_a?(PageParagraph) || paragraph.is_a?(Hash))
        paragraph = compile_paragraph(site_node,revision,paragraph,opts)
      end

      cls= paragraph.class
      cls_name = cls.to_s 

      if cls_name == "ParagraphRenderer::ParagraphOutput"
        return '' if paragraph.render_args[:nothing]
        css = paragraph.render_args.delete(:css)
        
        str = ''
        if paragraph.render_args[:text]
          str = paragraph.render_args[:text]
        elsif paragraph.render_args[:inline]
          @paragraph = paragraph
          str = render_to_string(paragraph.render_args)
        elsif paragraph.render_args[:partial]
          paragraph.render_args[:partial] = paragraph.render_args[:partial]
          paragraph.render_args[:locals] ||= {}
          paragraph.render_args[:locals][:renderer] = paragraph.rnd unless paragraph.render_args[:locals][:renderer]
          @paragraph = paragraph
          str = render_to_string(paragraph.render_args)
        elsif paragraph.render_args[:rjs]
          paragraph.render_args[:partial] = paragraph.render_args.delete(:rjs)
          paragraph.render_args[:locals] ||= {}
          paragraph.render_args[:locals][:renderer] = paragraph.rnd unless paragraph.render_args[:locals][:renderer]
          @paragraph = paragraph
          str = render_to_string(paragraph.render_args)
          str = "<script type='text/javascript'>" + str + "</script>" unless opts[:ajax]
          str
        elsif paragraph.render_args[:parent_rjs]
          paragraph.render_args[:partial] = paragraph.render_args.delete(:parent_rjs)
          paragraph.render_args[:locals] ||= {}
          paragraph.render_args[:locals][:renderer] = paragraph.rnd unless paragraph.render_args[:locals][:renderer]
          @paragraph = paragraph
          script =  render_to_string(paragraph.render_args)
          script = (script || '').
            gsub('\\', '\\\\\\').
            gsub(/\r\n|\r|\n/, '\\n').
            gsub(/['"]/, '\\\\\&').
            gsub('</script>','</scr"+"ipt>')
          str =  <<-EOF
<script type='text/javascript'>
   with(window.parent) { setTimeout(function() { window.eval('#{script}'); loc.replace('about:blank'); }, 1) }
</script>
EOF
        else 
          raise 'Invalid Paragraph Rendering'
        end
        # Add on the Site Feature CSS only if we're in edit mode, otherwise it'll come in on an include
        if opts[:edit]
          str = strip_script_tags(str)
          raise str.inspect if str.include?('<script')
        end
        str = "<style>#{css}</style>" + str if opts[:edit] && css
        return str
      elsif cls_name == "ParagraphRenderer::CachedOutput"
        return paragraph.output
      elsif paragraph.is_a?(String)
       opts[:edit] ? strip_script_tags(paragraph) : paragraph
      elsif paragraph.nil?
        "Nil"
        ""
      else
        ""
      end
    end


    def webiva_post_process_paragraph(txt) #:nodoc:
      @post_process_form_token_str ||= "<input name='authenticity_token' type='hidden' value='#{ form_authenticity_token.to_s}' />"
      txt.gsub!("<CMS:AUTHENTICITY_TOKEN/>",@post_process_form_token_str)
      txt
    end


    # Make sure any including controller
    # can render paragraphs from templates
    def self.append_features(base) #:nodoc:
      super

      base.send(:include,ModuleAppHelper)
      base.hide_action :render_output
      base.helper_method :compile_paragraph, :render_paragraph, :strip_script_tags
      base.helper_method :webiva_post_process_paragraph
      base.hide_action :find_page_from_path
      base.hide_action :handle_document_node
      base.hide_action :render_paragraph
      base.hide_action :compile_paragraph
      base.hide_action :webiva_post_process_paragraph
    end
    
    
   end
  
  
  # Base class for all different SiteNodeEngine outputs
  class Output 
    attr_accessor :status
    attr_accessor :paction
    attr_accessor :title
    
    def initialize
      @head = []
    end
    
    def redirect? 
      false
    end
    def document?
      false
    end
    def page?
      false
    end
    
  end
  
  # An instance of this is returned fron SiteNodeEngine#run if the
  # running the SiteNode results in a redirect
  class RedirectOutput < Output #:nodoc:all
    attr_accessor :redirect
    attr_accessor :user_level
    attr_accessor :user_value
    def redirect?
      true
    end
    
  end
  
  # An instance of this is returned fron SiteNodeEngine#run if the
  # running the SiteNode results in a HTML page
  class PageOutput < Output #:nodoc:all
    attr_accessor :language
    attr_accessor :title
    attr_accessor :site_template_id
    attr_accessor :css_site_template_id
    attr_accessor :head
    attr_accessor :body
    attr_accessor :partial
    attr_accessor :lightweight
    attr_accessor :doctype
    attr_accessor :revision
    attr_accessor :includes
    attr_accessor :page_connections
    attr_accessor :meta_description
    attr_accessor :meta_keywords
    attr_accessor :content_nodes
    attr_accessor :user_level
    attr_accessor :user_value

    def initialize
      super
      @includes = {}
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

    def page?
      true
    end
    
    def html(&block)
      self.body.each do |bd|
        yield bd
      end
    end
  end
  
  # An instance of this is returned fron SiteNodeEngine#run if the
  # running the SiteNode results in a date output or a file output  
  class DocumentOutput < Output 
    def initialize(options=nil)
      @options= options || {}
    
    end
    
    attr_reader :options
    
    def file?
      @options.has_key?(:file)
    end
    
    def file
      @options[:file]
    end
    
    def domain_file?
      @options.has_key?(:domain_file)
    end
    
    def data?
      @options.has_key?(:data)
    end
    
    def domain_file
      @options[:domain_file]
    end

    def path_args
      @options[:path_args]
    end

    def language
      @options[:language]
    end

    def data
     @options[:data]
    end
    
    def text?
      @options.has_key?(:text)
    end
    
    def text
      @options[:text]
    end
    
    def document?
      true
    end
  end
  
  # Exception that is raised when the site node doesn't
  # have an active version to display
  class NoActiveVersionException < RuntimeError
    attr :container
    attr :language
    
    def initialize(container,language)
      @container = container
      @language = language
    end
  end
  
  # Exception that is raised if there's not page matching
  # the path passed in
  class MissingPageException < RuntimeError
    attr :container
    attr :language
    
    def initialize(container,language)
      @container = container
      @language = language
    end
  end
    
  
  attr_reader :container
  attr_accessor :revision, :mode, :active_template, :language, :user, :path_args, :page_information
  attr_reader :controller
  attr_reader :forced_revision

  # To create a SiteNodeEngine, you need to pass it a container (usually a SiteNode, but
  # could also be a framework PageModifier in the editor)
  #
  # Options:
  # [:edit] 
  #   Set to true if we are in the editor
  # [:capture]
  #   Set to true to capture the output of the renderer instead of actually rendering a feature
  # [:display]
  #   The language to display if possible
  def initialize(container,options = {} )
    @container = container
    @capture_data = options[:capture]

    @preview = options[:preview]

    @path_args = options[:path] || []
    if options[:edit] 
      @mode = 'edit'
      # This is for editing
      if options[:edit].is_a?(PageRevision)
        @revision = options[:edit]
      else
        @revision = @container.page_revisions.find_by_id(options[:edit])
      end
      @language = @revision.language if @revision
    elsif options[:revision] 
      @revision = options[:revision]
      @forced_revision = @revision.id
      @language = @revision.language if @revision
    else
      @mode = 'display'
      # Otherwise this is for display
      # if we have a cached copy
      # create @page_information array 
      @language = options[:display] 
      @language ||= ( Locale.language ? Locale.language.code : Configuration.languages[0] )
    end
  end
  
  # Run an individual paragraph (instead of the entire container)
  def run_paragraph(paragraph,controller,user,options = {})
    nd = generate_page_information(controller,user)

    if !paragraph.info[:ajax] && (@mode != 'edit')
      raise 'Not an ajax paragraph'
    end

    @result = controller.compile_paragraph(@container.is_a?(SiteNode) ? @container : @container.site_node, 
                                           @page_information.revision,
                                           paragraph,
                                           :ajax => @mode=='edit' ? false : true,
                                           :editor => @mode == 'edit',
                                           :language => @language,
                                           :capture => @capture_data
                                           )
    result_cls = @result.class.to_s
    if result_cls == "ParagraphRenderer::ParagraphOutput" 
      return @result
    else 
      return nil
    end
  end

  # Run the site node engine, given an ActiveController and a user 
  # this will compile all paragraph and return the appropriate subclass of
  # SiteNodeEngine::Output
  def run(controller,user,options = {})
    
    nd = generate_page_information(controller,user)    

    @handlers = generate_node_engine_handlers()

    @handlers.each do |handler|
      @output = handler.before_page
      if @output.is_a?(SiteNodeEngine::Output)
        return @output
      end
    end

    # Check for a redirect node or a page information redirect
    if @output = handle_redirected_output(nd)
      return @output
    end
    
    # If we are rendering a document node, return it
    if @container.is_a?(SiteNode) && @container.node_type=='D'
      doc =  DocumentOutput.new(:path_args => @path_args, :language => @language )
      doc.paction = user.action("/document/download",:identifier => @container.domain_file.file_path)
      return doc
    end

    # Precompile any remaining paragraphs (Ignore when in edit mode)
    # This is done so any action can get handled ahead of time and redirects are handled properly
    if @mode != 'edit'
      # See how many page argument the page paragraphs are expecting
      max_path_level = calculate_max_path_level


      if max_path_level < @path_args.length  && @container.node_type != 'M' && @controller.is_a?(PageController)
        raise MissingPageException.new(@container,@language), "Page Not Found" 
      end
      page_connections = {}
      loop_cnt = 0
      unrendered = -1
      last_unrendered = 0
      repeat_count = 0
      first = true
      while first || ( unrendered > 0 && repeat_count < 3)
        first = false
        if last_unrendered == unrendered
          repeat_count += 1
        else
          repeat_count = 0
        end
        last_unrendered = unrendered
        loop_cnt += 1
        unrendered = 0

        @page_information.render_elements.each do |part|
          if part.is_a?(Hash)
            (0..part[:paragraphs].length).each do |idx|
              if part[:paragraphs][idx].is_a?(Hash) || part[:paragraphs][idx].is_a?(PageParagraph)
                part[:paragraphs][idx] =  PageParagraph.thaw(part[:paragraphs][idx]) if part[:paragraphs][idx].is_a?(Hash)

                # Title string is special because any paragraph could
                # generate one, so only if we're stuck and unrendered
                # to we need to generated one
                if  page_connections[:title_str].blank? && repeat_count > 1
                  page_connections[:title_str] = @page_information[:title_str] = create_page_title(nd)
                  page_connections[:title] = @page_information[:title]
                end

                result = controller.compile_paragraph(@container.is_a?(SiteNode) ?
                                                      @container : @container.site_node, 
                                                      @page_information.revision,
                                                      part[:paragraphs][idx],
                                                      :page_path => @page_path,
                                                      :language => @language,
                                                      :connections => page_connections,
                                                      :capture => @capture_data,
                                                      :repeat_count => repeat_count,
                                                      :preview => @preview)
                # We may not have a result if the page connections
                # aren't fullfilled yet
                if result
                  if result.is_a?(ParagraphRenderer::ParagraphRedirect) && !options[:error_page]
                    @output = RedirectOutput.new
                    @output.status = result.args.delete(:status)  if result.args.is_a?(Hash)
                    @output.user_level = result.user_level
                    @output.user_value = result.user_value

                    @output.paction = result.paction if result.paction
                    @output.redirect = result.args
                    return @output # exit early if we can 
                  elsif result.is_a?(ParagraphRenderer::ParagraphData)  && !options[:error_page]
                    # if we just have data, we need to do a direct output
                    return DocumentOutput.new(result.render_args)
                  end


                  if result.is_a?(ParagraphRenderer::ParagraphOutput)
                    @page_information[:user_level] = result.user_level if result.user_level && result.user_level > @page_information[:user_level].to_i

                    if result.user_value
                      @page_information[:user_value] ||= 0.0
                      @page_information[:user_value] += result.user_value.to_f
                    end

                    page_connections.merge!(result.page_connections  || {}) 
                    # Get any remaining includes 
                    result.includes.each do |inc_type,inc_value|
                      if inc_value.is_a?(Hash)
                        @page_information[:includes][inc_type] ||= {}
                        @page_information[:includes][inc_type].merge! inc_value
                      else
                        @page_information[:includes][inc_type] ||= []
                        @page_information[:includes][inc_type] +=  inc_value
                      end
                    end
                    if result.content_nodes
                      @page_information[:content_nodes] ||= []
                      @page_information[:content_nodes] += result.content_nodes
                    end
                    @page_information[:paction] = result.paction if result.paction
                  end

                  @page_information[:title].merge!(result.page_title)   if result.page_title

                  part[:paragraphs][idx] = result
                else
                  unrendered += 1
                end
              end
            end
          end
        end
      end 

      if unrendered > 0 
        #raise page_connections.inspect + ': Unrendered Paragraphs'
      end
    end
  


    # Finally, it we made it here, lets output a page
    @output = PageOutput.new

    @output.user_level = @page_information.user_level
    @output.user_value = @page_information.user_value
    @output.revision = @page_information.revision
    @output.status = '200'
    @output.language = @language

    # Create the title if not generated in compile phase
    @page_information[:title_str] = create_page_title(nd)  if @page_information.title_str.blank?
    @output.title = @page_information.title_str

    @output.meta_keywords = @page_information.revision.meta_keywords.blank? ? nil : @page_information.revision.meta_keywords
    @output.meta_description = @page_information.revision.meta_description.blank? ? nil : @page_information.revision.meta_description
    @output.site_template_id = @page_information.site_template_id
    @output.css_site_template_id = @page_information.css_site_template_id
    @output.body = @page_information.render_elements
    @output.includes = @page_information.includes
    @output.includes[:html_tag] ||= {}
    @output.includes[:html_tag]['xml:lang'] = @output.language
    @output.includes[:html_tag]['lang'] = @output.language
    @output.head = @page_information.head
    @output.paction = @page_information.paction
    @output.content_nodes = @page_information.content_nodes
    @output.partial = @page_information.partial
    @output.doctype = @page_information.doctype
    @output.lightweight = @page_information.lightweight
    @output
  end

  
 
  protected


  def handle_redirected_output(nd) #:nodoc:
    if nd.node_type == 'J'
      @output = RedirectOutput.new
      @output.status = 'Redirect'
      @output.redirect = nd.redirect_detail.destination
      return @output
      # If we have a page level redirect,
      # 
    elsif @mode != 'edit' &&  @page_information.redirect_to
      @output = RedirectOutput.new
      @output.status = 'Redirect'
      @output.redirect = @page_information.redirect_to
      return @output
    end

    return nil    
  end

  def generate_node_engine_handlers #:nodoc:
    @node_engine_handlers ||= [ NodeEngine::BuiltinHandler.new(self) ]
  end

  # Create the @page_information object - which contains all the info
  # necessary to render the object
  def generate_page_information(controller,user)
    @controller = controller
    @user = user
    @cached_info = false

    handlers = generate_node_engine_handlers

    @page_context = {}
    # Add in context from other handlers
    handlers.each { |hndler|  hndler.add_context(@page_context) }
    @page_context.stringify_keys!
    
    # If we are viewing (not editing) and 
    if(@mode != 'edit' && CMS_CACHE_ACTIVE)
      # see if this container is in the cache
      sorted_context_arr = @page_context.to_a.sort { |elm1,elm2| elm1[0] <=> elm2[0] }
      @path_hash_info =Digest::SHA1.hexdigest(sorted_context_arr.to_sentence)
      @page_information = DataCache.get_container(@container,@path_hash_info)
      # If so we do, turn it into a propert page information object
      if @page_information
        @page_information = NodeEngine::PageInformation.new(@page_information)
        @cached_info = true
      end               
    end
    
    nd = @container.is_a?(SiteNode) ? @container : @container.site_node 
    @page_path = nd.node_path
    if @path_args.length > 0
      @page_path += "/" + @path_args.join("/")
    end
    
    # Unless we already have a cache of page information
    unless @page_information || nd.node_type == 'J'
      compile_page_information(user)
    end

    if nd.node_type == 'J'
      @page_information = NodeEngine::PageInformation.new
    end
    
    # Cache the page information, if it's not already cached and we do have a cache active
    # (Ignore when in edit mode)
    if !@cached_info && @mode != 'edit' && CMS_CACHE_ACTIVE && ! @preview
     DataCache.put_container(@container,@path_hash_info,@page_information.to_hash)
    end
    
    return nd
  end

  
  # Compile the page information if we don't already have it in the cache
  def compile_page_information(user)
    
    module_rendering = @container.is_a?(SiteNode) && @container.node_type=='M'
    document_rendering = @container.is_a?(SiteNode) && @container.node_type=='D'

    @page_information = NodeEngine::PageInformation.new

    @page_information[:context] = @page_context.clone
    
    # Handle Modules
    if module_rendering

      # We need our revision from a framework 
      
      dispatcher = @container.dispatcher
      paragraphs = dispatcher.run(@path_args)
      
      @revision = @container.page_revisions.new(:revision_type => 'real', :language => @language)
    elsif document_rendering
      paragraphs= []
    else
      # Handle Pages / Frameworks
      unless @revision
        @revision = @container.page_revisions.find(:first,
              :conditions => "revision_type = 'real'" + (@mode !='edit' ? "AND active=1" : ""),
              :order => "language=#{SiteNode.quote_value(@language)} DESC"
              )
      end
      
      raise NoActiveVersionException.new(@container,@language), "No valid version found" unless @revision
      paragraphs = @revision.page_paragraphs.to_a
    end
    if @container.is_a?(SiteNode)
      site_node = @container
      nd = @container
    else 
      site_node = @container.site_node
      nd = @container.site_node
    end
    
    # Handle case where we have no paragraphs
    if paragraphs.length == 0 && @mode != 'edit'
      replacement_page_path = nil
      site_node.children.each do |page|
        if page.node_type == 'J'
         replacement_page_path = page.redirect_detail.destination
         break;
        else
         rev = page.page_revisions.find(:first,
              :conditions => "revision_type = 'real' AND active=1",
              :order => "language=#{SiteNode.quote_value(@language)} DESC"
              )
          if rev && rev.page_paragraphs.length > 0
            replacement_page_path = page.node_path
            break;
          end
        end
      end
      if replacement_page_path
        @page_information[:redirect_to] =  replacement_page_path
        return
      end
      
    end

    paragraphs.reverse_each do |para|
      @page_information.zone_paragraphs[para.zone_idx] ||= []
      
      # Make sure we don't add extra framework paragraphs
      # If we have a clear
      if(para.display_type == 'clear' && !@page_information.zone_clears[para.zone_idx])
        @page_information.zone_clears[para.zone_idx] = @revision.id
        @page_information.zone_locks[para.zone_idx] = false
      end
      @page_information.zone_paragraphs[para.zone_idx].unshift(para)
    end    
    while nd
      mods = nd.modifiers(nd == site_node,@container.is_a?(SiteNode) ? nil : @container.position) # get the modifiers (only the pre ones if this is the node we are looking at)
      self.add_modifiers(mods)
      nd = nd.parent
    end
    
    unless document_rendering 
      if !@page_information.site_template_id
        @active_template = SiteTemplate.find(:first) || SiteTemplate.create(:name => 'Default Template'.t,:template_html => "<cms:zone name='Main'/>")
        @page_information[:site_template_id] = @active_template.id
      end
      @page_information[:css_site_template_id] = @active_template.parent_id ? @active_template.parent_id : @active_template.id
      
      @page_information[:head] = SiteTemplate.render_template_head(@page_information[:css_site_template_id],@language)
      @page_information[:doctype] = @active_template.doctype.blank? ? nil : @active_template.doctype
      @page_information[:partial] = @active_template.partial?
      @page_information[:lightweight] = @active_template.lightweight?

      
      if @mode == 'edit'
        @page_information[:revision] = @revision
      else
        # Just save the attributes unless we are editing
        @page_information[:revision] = DefaultsHashObject.new(@revision.attributes)
      end
    
      self.render_page_elements()
    end  
    self.cleanup_page_information
  end
  
  
  
  # Get a the page_information render_elements - an array of static
  # content and paragraph attribute hashes
  def render_page_elements()
    @active_template = SiteTemplate.find(@page_information.site_template_id) unless @active_template

    variables = (@revision.display_variables || {}).clone

    # Generate an array of strings (for static content),
    # and hashs (for zones with paragraphs)
    parts = self.generate_template_output(variables)


    # List of javascript and CSS includes
    includes = {}
    
    # Compile the parts together where possible for speedier rendering
    if @mode != 'edit'
      compiled_parts = [""] # start off with a blank string
      
      parts.each do |part|
        if part.is_a?(String)
          if compiled_parts[-1].is_a?(String)
            compiled_parts[-1] += part
          else
            compiled_parts << part
          end
        elsif part[:paragraphs]
          part[:paragraphs].each do |para|
            # Pre process the paragraph for storing in page information
            pre_process_paragraph(compiled_parts,para,part[:zone_idx],includes)
          end
        else # we have a variable
          value = @active_template.render_variable(part[:variable],part[:value],@language)
          if compiled_parts[-1].is_a?(String)
            compiled_parts[-1] += value.to_s
          else
            compiled_parts << value
          end
        end
        
      end
      @page_information[:render_elements] = compiled_parts
    else
      # Just get the parts as they are if we are in edit mode
      @page_information[:render_elements] = parts
    end

    # Save the includes from the cached paragraphs
    @page_information[:includes] = includes


  end

  def cleanup_page_information
    # Kill the zone_paragraphs hash as we don't need to store it in
    # page information
    @page_information[:zone_paragraphs] = nil

  end

  # Add any modifiers on the rendering stack
  def add_modifiers(mods)
    # Doing everything in reverse because of direction items will be added
   
    mods.reverse_each do |mod|
      mod.apply_modifier!(self,@page_information)
    end
  end

  # Get a list of parts making up the template output
  def generate_template_output(variables)
    parts = []
    @active_template.render_html(@language) do |part| 
      parts << part.body
      if(part.zone_position != -1)
        if @mode == 'edit' || @page_information.zone_paragraphs[part.zone_position].is_a?(Array)
          zone = @active_template.site_template_zones.detect {  |zn| zn.position == part.zone_position } if @mode == 'edit'
          parts.push({:zone_idx => part.zone_position, 
                       :zone_name => zone ? zone.name : '(Undefined)'.t,
                       :paragraphs => @page_information.zone_paragraphs[part.zone_position] || [],
                       :locked => @page_information.zone_locks[part.zone_position]
                     })
        end
      elsif !part.variable.blank?
        parts.push({:variable => part.variable, :value => variables[part.variable] })
      end
    end

    parts
  end
  
  # Pre process the paragraph for storing in page information
  # - if its a basic paragraph, just output
  # - if its a cachable paragraph, render it
  # - otherwise just at a hash of attributes in for deferred rendering
  def pre_process_paragraph(compiled_parts,para,zone_idx,includes)
    body = nil
    skip = false
    if !para.display_module
      if !para.display_body.blank? && para.display_body != ''
        if @page_information.lightweight
          body = para.display
        else
          body = "<div class='#{para.display_type}_paragraph'>" +  para.display + "</div>"
        end
      else
        skip=true
      end
    else
      info = para.info
      if info[:cache] == true
        output =
          controller.compile_paragraph(
                                       @container.is_a?(SiteNode) ? @container : @container.site_node,
                                       @page_information.revision,para,
                                       :page_path => @page_path, :language => @language, :preview => @preview)
        output.includes.each do |inc_type,inc_arr| 
          includes[inc_type] ||= []
          includes[inc_type] += inc_arr
        end

        body = controller.render_paragraph(@container.is_a?(SiteNode) ? @container : @container.site_node, @page_information.revision,output, :language => @language, :preview => @preview)
      end
    end
    
    if body
      if compiled_parts[-1].is_a?(String)
        compiled_parts[-1] += body
      else
        compiled_parts << body
      end
    elsif !skip
      
      if compiled_parts[-1].is_a?(String)
        compiled_parts << {:zone_idx => zone_idx,
          :paragraphs => [ para.cache_attributes  ]
        }
      else
        compiled_parts[-1][:paragraphs] << para.cache_attributes 
      end
    end

  end

  # See how many path arguments the paragraphs eat up,
  # so we can do a 404 if there isn't a valid path
  def calculate_max_path_level
    max_path_level = 0
    @page_information.render_elements.each do |part|
      if part.is_a?(Hash)
        (0..part[:paragraphs].length).each do |idx|
          if part[:paragraphs][idx].is_a?(Hash) || part[:paragraphs][idx].is_a?(PageParagraph)
            part[:paragraphs][idx] =  PageParagraph.thaw(part[:paragraphs][idx]) if part[:paragraphs][idx].is_a?(Hash)
            if part[:paragraphs][idx].connections && part[:paragraphs][idx].connections[:inputs] 
              part[:paragraphs][idx].connections[:inputs].each do |input_type,input|
                if input[1].to_s.include?("page_arg_")
                  level = input[1].to_s[-1..-1].to_i + 1
                  max_path_level = level if level > max_path_level
                end
              end
            end
          end
        end
      end
    end

    max_path_level
  end
  

  # Generate the title of the page from the revision and any set_title
  # calls in the paragraph
  def create_page_title(nd)
    title_str = @page_information.revision.title if @page_information.revision
    
    if @page_information.title && @page_information.title.length > 0
      @page_information.title.stringify_keys!
      @page_information.title['title'] = @page_information.title['default'] if  @page_information.title['default']

      if title_str.blank?
        title_str = @page_information.title['default'] || @page_information.title.values.join(" ")
      else
        title_str = DomainModel.variable_replace( title_str,@page_information.title)
      end
    end

    if title_str.blank?
      if  @page_information.revision
        title_str = ( @page_information.revision.title.to_s.empty? ? nd.title.to_s.titleize :    @page_information.revision.title )
      else
        title_str = nd.title.to_s.titleize
      end
    end

    title_str
  end
  
end
