

class Dashboard::WidgetBase

  attr_reader :output_title, :output, :includes, :options, :editor_widget, :icon

  attr_reader :controller 

  include ActiveTable::Controller

  def initialize(options,editor_widget)
    @options = options
    @editor_widget = editor_widget
  end

  def self.available_widgets
    []
  end

  # We don't use the handler info for widgets
  # so just return a dummy
  def self.webiva_widget_handler_info  #:nodoc:
    {  :name => "Widget Handler"}
  end

  def controller_render_widget(widget_name,controller)
    @controller = controller
    self.send(widget_name)
  end

  def self.widget(name,options={})
    options[:name] ||= name.titleize
    options[:title] ||= options[:name]
    widgets = self.available_widgets + [[ self.to_s.underscore, name.to_s, options ]]
    class << self; self; end.send(:define_method,:available_widgets) do
      widgets
    end
  end

  def set_icon(val)
    @icon = val
  end

  def self.widget_information(name)
    self.available_widgets.detect { |widget| widget[1] == name }[2]
  end

  def require_js(*js_files)
    @includes ||= { }
    @includes[:js] ||= []
    @includes[:js] += js_files[0].is_a?(Array) ? js_files[0] : js_files
  end

  def require_css(*css_files)
    @includes ||= { }
    @includes[:css] ||= []
    @includes[:css] += css_files[0].is_a?(Array) ? css_files[0] : css_files
  end

  def render_widget(args)
    args[:locals] ||= { }
    args[:locals][:widget] = editor_widget
    @output = @controller.send(:render_to_string,args)
  end

  def render
    raise "Use render_widget to render a widget"
  end

  def method_missing(method,*args)
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
