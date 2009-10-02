# Copyright (C) 2009 Pascal Rettig.

# Controller which handle administration of page paragraphs
# are derived from this
class ParagraphController < CmsController
  include SiteNodeEngine::Controller

  before_filter :validate_paragraph
  
  helper :paragraph, :page
  
  layout nil
  
  attr_reader :paragraph
  
  protected

  
  def self.user_actions(names)
    self.skip_before_filter :validate_paragraph, :only => names
    self.skip_before_filter :check_ssl, :only => names
    self.skip_before_filter :validate_is_editor, :only => names
  end
  
  def render_paragraph_update
    render :template => 'edit/paragraph_update'
    # force a javscript content type if we're updating
    headers['Content-Type'] = 'text/javascript; charset=utf-8'
  end
  
  def render_module_paragraph_update
    render_paragraph_update
  end
  

  def handle_module_paragraph_update(opts)
    handle_paragraph_update(opts)
  end

  def handle_paragraph_update(opts)
    if request.post?
      if opts.valid?
        @paragraph.data = opts.to_h
        @paragraph.site_feature_id = params[:site_feature_id]
        @paragraph.save
        render_paragraph_update
        return
      end
    end
  end

  def paragraph_options(paragraph_name)
  
    options_class = self.class.to_s + "::" + paragraph_name.to_s.classify + "Options"
    options_class.constantize.new(@paragraph.data)
  end

  def validate_paragraph
      # Validate Access to the paragraph
      @container_type = params[:path][0] == 'page' ? 'site_node' : 'site_node_modifier'
      @container_cls = @container_type.camelcase.constantize
      @page = @container_cls.find(params[:path][1])
      @site_node = @container_type == 'site_node' ? @page : @page.site_node
      @revision = @page.page_revisions.find(params[:path][2])
      @paragraph = @revision.page_paragraphs.find(params[:path][3])
      @paragraph_index = params[:path][4].to_i
      @site_template_id = params[:site_template_id]
  end

  def self.editor_header(title,permission=nil)
    sing = class << self; self; end
    sing.send :define_method, :get_editor_header do 
      return [title,permission]
    end 
  end
  
  def self.editor_for(paragraph,args = {})
    editors = self.get_editor_for || []
    args[:features] = [ args[:feature] ] if args[:feature]
    args[:feature] = args[:features][0] if args[:features].is_a?(Array)
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
       @options = #{paragraph.to_s.classify}Options.new(params[:#{paragraph}] || paragraph.data || {})
       return if handle_module_paragraph_update(@options)
      end
      METHOD
    end
    
    self.class_eval method_src,__FILE__,__LINE__
  end
  
  def self.get_editor_for
    []
  end
  
  def self.get_editor_header
    nil
  end


  def self.get_editor_paragraphs
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
                para_info = [ 'editor', para[0].to_s, para[1][:name] || para[0].humanize, "/editor/#{controller_name}", para[1][:features] || [] ]
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
  
  
  def self.get_editor_controllers
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
