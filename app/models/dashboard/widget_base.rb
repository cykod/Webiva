

class Dashboard::WidgetBase

  attr_reader :output_title, :output, :includes, :options

  attr_reader :controller 

  def initialize(options)
    @options = options
  end

  def self.available_widgets
    []
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
    @output = @controller.send(:render_to_string,args)
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
