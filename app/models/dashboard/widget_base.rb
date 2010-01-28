
=begin rdoc
Base class which all dashboard widgets should subclass. To add a dashboard widget you
need to add a handler to your admin controller like:

    register_handler :webiva, :widget, "Feedback::FeedbackWidget"

Then create the widget class with a least one "widget" (it could define multiple), for example a shortened version of the
Feedback comments widget looks like:

     class Feedback::FeedbackWidget < Dashboard::WidgetBase
     
       widget :comments, :name => "Feedback: Display Recent Comments", :title => "Recent Comments", :permission => :feedback_editor
      
       def comments
         set_icon 'feedback_icon.png'
         @comments = Comment.find(:all, :include => :end_user, :order => 'posted_at DESC')
         render_widget :partial => '/feedback/feedback_widget/comments', :locals => { :comments => @comments }
       end
       
       class CommentsOptions < HashModel
         attributes :count => 10
     
         integer_options :count
         validates_numericality_of :count
     
         options_form(
                      fld(:count, :text_field)
                      )
       end
     end
     
The partial that is rendered is a full path to the body of the widget

See vendor/modules/feedback/app/models/feedback/feedback_widget.rb for the full feedback widget definition.
=end
class Dashboard::WidgetBase

  attr_reader :output_title, :output, :includes, :options, :editor_widget, :icon, :first, :title_link
  attr_writer :first

  attr_reader :controller 

  include ActiveTable::Controller

  def initialize(options,editor_widget)
    @options = options
    @editor_widget = editor_widget
    @first = first
  end

  # Is this the first time we're rendering this widget, if that's the case
  # we may not have required js or css files
  def first? 
    @first
  end

  def self.available_widgets #:nodoc
    []
  end

  # We don't use the handler info for widgets
  # so just return a dummy
  def self.webiva_widget_handler_info  #:nodoc:
    {  :name => "Widget Handler"}
  end

  def controller_render_widget(widget_name,controller) #:nodoc:
    @controller = controller
    self.send(widget_name)
  end

  # Register a widget that this class renders
  #
  # Options: 
  # [:name]
  #   Display name of the widget when selector from the available widgets, defaults to titleized widget name
  # [:title[
  #   Default title for the widget, defaults to name
  def self.widget(name,options={})
    options[:name] ||= name.titleize
    options[:title] ||= options[:name]
    widgets = self.available_widgets + [[ self.to_s.underscore, name.to_s, options ]]
    class << self; self; end.send(:define_method,:available_widgets) do
      widgets
    end
  end

  # Set the icon file that this widget should use
  # See public/themes/standard/icons/content for available icons
  def set_icon(val)
    @icon = val
  end

  def self.widget_information(name) #:nodoc
    w = self.available_widgets.detect { |widget| widget[1] == name }
    w[2] if w
  end

  # Include a js file that this widget needs,
  # may not be included on the first render (can check with first?)
  def require_js(*js_files)
    @includes ||= { }
    @includes[:js] ||= []
    @includes[:js] += js_files[0].is_a?(Array) ? js_files[0] : js_files
  end

  # Include a css file that this widget needs
  # may not be included on the first render (can check with first?)
  def require_css(*css_files)
    @includes ||= { }
    @includes[:css] ||= []
    @includes[:css] += css_files[0].is_a?(Array) ? css_files[0] : css_files
  end

  # Render this widget, accepts the same arguments as render_to_string (however
  # it should only render partials or text directly)
  def render_widget(args)
    args[:locals] ||= { }
    args[:locals][:widget] = editor_widget
    @output = @controller.send(:render_to_string,args)
  end

  # Makes the title of the widget a link
  def set_title_link(url)
    if url.is_a?(Hash)
      @title_link = @controller.send(:url_for,url)
    else
      @title_link = url
    end
  end

  def render #:nodoc
    raise "Use render_widget to render a widget"
  end

  def method_missing(method,*args) #:nodoc
    if !@controller
      super
    end
    if args.length > 0
      @controller.send(method,*args)
    else
      @controller.send(method)
    end
  end

end
