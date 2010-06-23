# Copyright (C) 2009 Pascal Rettig.

=begin rdoc
ParagraphController's are used to define the page editor 
characteristics of one or more paragraphs.

They are one part of the trinty of classes used for 
configuring and rendering paragraphs (ParagraphFeature and ParagraphRenderer
are the other two).

They can also be used to handle ajax requests from paragraphs that do not
need to go through the normal lock system of Webiva.


=== Example

A standard ParagraphController generally has a editor_header call followed by
a number of editor_for calls (one for each paragraph this controller is the
editor for) followed by a number options class definitions.

For example the PageController from the PollDemo tutorial looks like:

     class PollDemo::PageController < ParagraphController
     
       editor_header 'Polldemo Paragraphs'
       
       editor_for :view, :name => "View", :feature => :poll_demo_page_view
       editor_for :list, :name => "List", :feature => :poll_demo_page_list
      
       class ViewOptions < HashModel
         attributes :graph_width => 300, :graph_height => 150
         integer_options :graph_width, :graph_height
         validates_numericality_of :graph_width, :graph_height
       end
       
       ...snip...
     end



This indicates that there are two paragraphs, 'view' and 'list' that this controller
is the editor for. They will appear in the editor when you try to add a paragraph under
the heading "Polldemo Paragraphs". The ListOptions class has been cut, but the ViewOptions
model shows you the options that the :view paragraph needs to display itself.

 === Implicit methods

Calling editor_for :view will add an implict method called view to your controller
that is used for editing the paragraph. The implict method can be overwritten
if you need any additional functionality or to do anything in the controller. 

For example you could override the implict view method with something like:

     def view 
       @options = paragraph_options(:view)
       return if handle_paragraph_update(@options)
       .. Do other stuff, fetch some data/handlers/etc...
       render :action => 'view' # this is the default behavior and can be left out
     end

The key to the above is the call to handle_paragraph_update with the paragraph options object,
this will check if the object is valid and return update the paragraph (by re-rendering it)
and return true. Otherwise, it will return false and it will redisplay the paragraph 
options form.

=== Paragraph Views

The views for the paragraph-related methods inside of ParagraphController's are generally
just short options forms of the form:

      <div class='cms_form'>
         <% paragraph_options_form_for :paragraph_name do |f| %>
             <%= f.field_type :field_1, ... %>
             <%= f.field_type :field_2, ... %>
             ... More fields ..
         <% end -%>
      </div>

The paragraph_options_form_for handles the submit and cancel links as well as displaying
a dropdown of available features.

TODO: update to the automatic forms when desired


=end
class ParagraphController < CmsController
  include SiteNodeEngine::Controller

  before_filter :validate_paragraph
  
  helper :paragraph, :page
  
  layout nil
  
  attr_reader :paragraph
  
  protected

  # Call this to use the methods named inside as   
  # standard controller methods (not related to site nodes)
  def self.user_actions(*names)
    names = names[0] if names[0].is_a?(Array)
    self.skip_before_filter :validate_paragraph, :only => names
    self.skip_before_filter :check_ssl, :only => names
    self.skip_before_filter :validate_is_editor, :only => names
  end
  
  
  def render_paragraph_update #:nodoc:
    render :template => 'edit/paragraph_update'
    # force a javscript content type if we're updating
    headers['Content-Type'] = 'text/javascript; charset=utf-8'
  end
  
  def render_module_paragraph_update #:nodoc:
    render_paragraph_update
  end
  

  def handle_module_paragraph_update(opts) #:nodoc:
    handle_paragraph_update(opts)
  end

  # Pass this a paragraph options object and it will check if the
  # object is valid, update the paragraph object, render the
  # paragraph update, and return true.
  # if it's not valid? it will return false.
  # See the ParagraphController class docs for more details
  def handle_paragraph_update(opts)
    if request.post?
      if opts.valid?
        @paragraph.data = opts.to_h
        @paragraph.site_feature_id = params[:site_feature_id] if params.has_key?(:site_feature_id)
        @paragraph.save
        render_paragraph_update
        return true
      end
    end
  end

  # Class level method to return paragraph options for this class
  def self.paragraph_options(paragraph_name,data)
    options_class = self.to_s + "::" + paragraph_name.to_s.camelcase + "Options"
    begin
      options_class.constantize.new(data)
    rescue NameError
      logger.error "class not found #{options_class}"
      nil
    end
  end

  # Returns paragraph options for a paragraph (either pulling from params of the same
  # name as the paragraph or from paragraph objects data)
  def paragraph_options(paragraph_name)
    self.class.paragraph_options(paragraph_name,params[paragraph_name] || @paragraph.data)
  end

  def validate_paragraph #:nodoc:
      # Validate Access to the paragraph
      @container_type = params[:path][0] == 'page' ? 'site_node' : 'site_node_modifier'
      @container_cls = @container_type.camelcase.constantize
      @page = @container_cls.find(params[:path][1])
      @site_node = @container_type == 'site_node' ? @page : @page.site_node
      @version = @site_node.site_version
      SiteVersion.override_current(@version)
      
      @revision = @page.page_revisions.find(params[:path][2])
      @paragraph = @revision.page_paragraphs.find(params[:path][3])
      @paragraph_index = params[:path][4].to_i
      @site_template_id = params[:site_template_id]
  end

  # Sets the header paragraphs in this controller will appear under
  def self.editor_header(title,permission=nil)
    sing = class << self; self; end
    sing.send :define_method, :get_editor_header do 
      return [title,permission]
    end 
  end
  
=begin rdoc
 Adds a paragraph that this controller is the editor for

### Options
 [:feature]
   Symbol representing the name of feature that this paragraph users
 [:no_options]
   This paragraph doesn't have any options, so don't show the options dialog
 [:name]
   Textual name for the paragraph that shows up in the "Add paragraph" and in the paragraph header
 [:inputs]
   A list of page connection inputs of the form:
      
       [[ :input_name_1, "Input Description", :input_type_1], ... ]
              or
       { :input_1 => [[ :input_name_1, "Input Description", :input_type_1], ... ],
         :input_2 => [[ :input_name_2, "Input Description2", :input_type_2], ... ] }

   The first one will add a default input called :input, while the second way allows you
   to define multiple different inputs (for example, a book page might have an input called
   "book" and one called "page" 
 [:outputs]
   A list of page connection outputs of the form:
 
       [[:output_name_1, "Output Description", :output_type],... ]

   Inputs and outputs are matched by types (the third element of the array)

=end  
  def self.editor_for(paragraph,args = {})
    editors = self.get_editor_for || []
    args[:features] = [ args[:feature].to_s ] if args[:feature]
    args[:feature] = args[:features][0].to_s if args[:features].is_a?(Array)
    args[:name] ||= paragraph.to_s.titleize
    editors << [ paragraph, args ]
    sing = class << self; self; end
    sing.send :define_method, :get_editor_for do 
      editors
    end 
    sing.send :define_method, "#{paragraph}_info".to_sym do 
      args
    end
    
    if args[:no_options]
      method_src = <<-METHOD
      def #{paragraph}
       render :inline => "<script>RedBox.close();</script>"
      end
      METHOD
    else
      method_src = <<-METHOD
      def #{paragraph}
        @options = self.class.paragraph_options(:#{paragraph},params[:#{paragraph}] || paragraph.data)
       return if handle_paragraph_update(@options)

       if @options.options_partial
         render :template => '/edit/edit_paragraph', :locals => {:paragraph_title => "#{args[:name]} Options",
                                         :paragraph_action => "#{paragraph}" }
       end 
      end
      METHOD
    end
    
    self.class_eval method_src,__FILE__,__LINE__
  end
  
  def self.get_editor_for #:nodoc:
    []
  end
  
  def self.get_editor_header #:nodoc:
    nil
  end


  def self.get_editor_paragraphs #:nodoc:
    # Find all the controllers in the 'editors' subdirectory,
    # get the class constant
    # Call the class methods to get the title,
    # and the 
    
    paragraphs = []
    Dir.glob("#{RAILS_ROOT}/app/controllers/editor/[a-z0-9\-_]*_controller.rb") do |file|
      if file =~ /\/([a-z0-9\-_]+)_controller.rb$/
        controller_name = $1
        if controller_name != 'admin'
	  cls = "Editor::#{controller_name.camelcase}Controller".constantize
	  header = cls.get_editor_header
	  paras = cls.get_editor_for
	  

	  if paras
            ctrl_paragraphs = []
	    paras.each do |para|
	      unless para[1][:hidden]
                para_info = [ 'editor', para[0].to_s, para[1][:name] || para[0].humanize, "/editor/#{controller_name}", para[1][:features] || [], nil,  para[1][:legacy] ? true : false ]
		ctrl_paragraphs << para_info
	      end
	    end
  	    paragraphs << [header[0],header[1],ctrl_paragraphs] if header
	  end

	end
      end
    end
    paragraphs

  end
  
  
  def self.get_editor_controllers #:nodoc:1
    # Find all the controllers in the 'editors' subdirectory,
    
    controllers = []
    Dir.glob("#{RAILS_ROOT}/app/controllers/editor/[a-z0-9\-_]*_controller.rb") do |file|
      if file =~ /\/([a-z0-9\-_]+)_controller.rb$/
        controller_name = $1
        cls = "Editor::#{controller_name.camelcase}Controller".constantize
        controllers << cls
      end
    end
    
    controllers
  end  
end
