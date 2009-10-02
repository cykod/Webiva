require 'json'
module OFC2
  # specjal module included in each class
  # with that module we add to_hash and to_json methods
  # there is also a method_missing which allow user to set/get any instance variable
  # if user try to get not setted instance variable it return nil and generate a warn
  module OWJSON
    def to_hash
      self.instance_values
    end
    alias :to_h :to_hash
    def to_json
      to_hash.to_json
    end
    def method_missing(method_id, *arguments)
      a = arguments[0] if arguments and arguments.size > 0
      method = method_id.to_s
      if method =~ /^(.*)(=)$/
        self.instance_variable_set("@#{$1.gsub('_','__')}", a)
      elsif method =~ /^(set_)(.*)$/
        self.instance_variable_set("@#{$2.gsub('_','__')}", a)
      elsif self.instance_variable_defined?(method_id)
        self.instance_variable_get("@#{method_id.to_s.gsub('_','__')}") # that will be return instance variable value or nil, handy
      else
        #        well there is no instance variable and user don't wan't to define any
        #         maybe better return nil and warn that rise exception(call super) ?
        warning = <<-EOF
          !!! there is no instance variable named #{method_id} !!!
          - if You want to set instance variable use variable= or set_variable(var) methods
          - if You want to get variable call object for variable: obj.variable
          - You can call only for variables You set before
        EOF
        warn(warning)
        nil
      end
    end
  end

  def self.included(controller)
    controller.helper_method(:ofc2, :ofc2_inline)
  end

  # generate a ofc object using Graph object
  #  +width+ width for div
  #  +height+ height for div
  #  +graph+ a OFC2::Graph object
  #  +base+ uri for graph, default '/'
  #  +id+ id for div with graph, default Time.now.usec
  def ofc2_inline(width, height, graph, base='/', id=Time.now.usec)
    # TODO: generating more than one graph with ofc2_inline on the same page is currently impossible
    div_name = "flashcontent_#{id}"
    <<-EOF
      <div id="#{div_name}"></div>
      <script type="text/javascript">

        function #{div_name}_data(){
          return '#{graph.render}';
        };

        // i'm not shure that is necessary
        function findSWF(movieName) {
          if (navigator.appName.indexOf("Microsoft")!= -1) {
            return window[movieName];
          } else {
            return document[movieName];
          }
        };

        swfobject.embedSWF(
          '#{base}open-flash-chart.swf', '#{div_name}',
          '#{width}', '#{height}','9.0.0', 'expressInstall.swf',
          {'get-data':'#{div_name}_data'} );

      </script>
    EOF
  end

  # generate a ofc object using data from url
  #  +width+ width for div
  #  +height+ height for div
  #  +url+ an url which return data in json format
  #  +base+ uri for graph, default '/'
  #  +id+ id for div with graph, default Time.now.usec
  def ofc2(width, height, url, base='/', id =Time.now.usec)
    div_name = "flashcontent_#{id}"
    <<-EOF
      <div id='#{div_name}'></div>
      <script type="text/javascript">
   
          var so = new SWFObject("#{base}open-flash-chart.swf",'mpl','#{width}','#{height}','7');
              so.addVariable('data-file',"#{base}#{url}");
              so.write('#{div_name}');

      </script>
    EOF
  end

  # insance variables:
  #
  #  +style+ style for element, it's is in css style eg. "{font-size: 20px; color: #FF0F0F; text-align: center;}"
  #  +text+ text for element
  class Element
    include OWJSON
    # You can initialize Elemnt while creating it, otherwise it will be have default valiues
    #  +text+ = ''
    #  +css+ = "{font-size: 20px; color: #FF0F0F; text-align: center;}"
    def initialize(text = '', css = "{font-size: 20px; color: #FF0F0F; text-align: center;}")
      @text= text
      @style= css
    end
  end

  # documentation is the same as Element class
  class XLegend <  Element ;end
  # documentation is the same as Element class
  class Title < Element ;end
  # documentation is the same as Element class
  class YLegend <  Element ;end

  # YAxisBase
  #
  #  +stroke+
  #  +tick_length+
  #  +colour+
  #  +min+
  #  +max+
  #  +steps+
  #  +labels+
  class YAxisBase
    include OWJSON

    # set colour and grid_colour at once
    # there is also an alias colours=
    #
    #  +colour+ colour for labels eg. #FF0000
    #  +grid_colour+ colour for grid eg. #00FF00
    def set_colours( colour, grid_colour )
      set_colour( colour )
      set_grid_colour( grid_colour )
    end
    alias_method :colours=, :set_colours


    # set range at once
    # there is also an alias range=
    #
    #  +min+ minimum for y_axis
    #  +max+ maximum for y_axis
    #  +steps+ how many steps skip before print label
    def set_range( min, max, steps=1 )
      set_min(min)
      set_max(max)
      set_steps( steps )
    end
    alias_method :range=, :set_range

    # set offset for axis, these is handy when You want to 3d graph render
    # there is also an alias offset=
    def set_offset( off )
      @offset = off ? 1 : 0
    end
    alias_method :offset=, :set_offset

  end

  class YAxis < YAxisBase
    #    # left axis control grid colour, but right not
    #    def set_grid_colour(color = '#ff0000')
    #      @grid__colour = color
    #    end
    #    alias_method :grid_colour=, :set_grid_colour
  end
  class YAxisRight < YAxisBase
  end

  # x_axis
  #
  #  +stroke+
  #  +tick_length+
  #  +colour+
  #  +tick_height+
  #  +grid_colour+
  #  +min+
  #  +max+
  #  +steps+
  #  +labels+
  #  +offset+
  class XAxis
    include OWJSON

    # well it must be done this way because instance variable name can't be started by number
    %w(3d).each do |method|
      define_method("set_#{method}") do |a|
        self.instance_variable_set("@___#{method}", a)
      end
      define_method("_#{method}=") do |a|
        self.instance_variable_set("@___#{method}", a)
      end
      define_method("#{method}") do
        self.instance_variable_get("@___#{method}")
      end
    end
    # set +colour+ and +grid_colour+, use a css color style '#ff00ff'
    def set_colours( colour, grid_colour )
      @colour= colour
      @grid_colour= grid_colour
    end

    # o is treat as a logic
    def set_offset( o )
      @offset = !!o
    end

    # helper method to make the examples simpler.
    def set_labels_from_array( a )
      x_axis_labels = XAxisLabels.new
      x_axis_labels.set_labels( a )
      x_axis_labels.set_steps( @steps ) if @steps
      @labels = x_axis_labels
    end
    alias_method :labels_from_array=, :set_labels_from_array
    def set_range( min, max )
      @min=min
      @max=max
    end
  end

  #  +text+
  #  +colour+
  #  +size+
  #  +rotate+
  #  +visible+
  class XAxisLabel
    include OWJSON
    def initialize( text = nil, colour = nil, size= nil)
      @text= text if text
      @colour= colour if colour
      @size= size if size
    end
    def set_vertical
      @rotate = "vertical"
    end
    alias_method :vertical, :set_vertical

    def set_horizontal
      @rotate = "horizontal"
    end
    alias_method :horizontal, :set_horizontal
  end

  #  +steps+
  #  +labels+
  #  +colour+
  #  +size+
  class XAxisLabels
    include OWJSON
    def set_vertical()
      @rotate = "vertical"
    end
  end

  # scatter value
  #
  #  +x+
  #  +dot_size+
  #  +y+
  class ScatterValue
    include OWJSON
    def initialize( x, y, dot_size=-1 )
      @x = x
      @y = y
      set_dot_size(dot_size) if dot_size > 0
    end
  end

  #  +colour+
  #  +dot_size+
  #  +values+
  class Scatter
    include OWJSON
    def initialize( colour, dot_size )
      @type      = "scatter"
      set_colour( colour )
      set_dot_size( dot_size )
    end
  end



  #  +title+
  #  +x_axis+
  #  +y_axis+
  #  +y_axis_right+
  #  +x_legend+
  #  +y_legend+
  #  +bg_colour+
  #  +elements+
  class Graph
    include OWJSON

    # it must be done in that way because method_missing method replace _ to __,
    # maybe I add seccond parameter to handle with that
    %w(x_axis y_axis y_axis_right x_legend y_legend bg_colour).each do |method|
      define_method("set_#{method}") do |a|
        self.instance_variable_set("@#{method}", a)
      end
      define_method("#{method}=") do |a|
        self.instance_variable_set("@#{method}", a)
      end
      define_method("#{method}") do
        self.instance_variable_get("@#{method}")
      end
    end

    def initialize
      @title = Title.new( "Graph" )
      @elements = []
    end

    def add_element( e )
      @elements << e
    end
    alias_method :<<, :add_element

    def render
      s = to_json
      # everything about underscores
      s.gsub!('___','') # that is for @___3d variable
      s.gsub!('__','-') # that is for @smt__smt variables
      # variables @smt_smt should go without changes
      s
    end
  end

  # line chart
  #
  #  +values+
  #  +width+
  #  +colour+
  #  +font_size+
  #  +dot_size+
  #  +halo_size+
  #  +text+
  class LineBase
    include OWJSON
    def initialize(text = 'label text', font_size='10px', values = [9,6,7,9,5,7,6,9,7])
      @type      = "line_dot"
      @text      = text
      @font__size = font_size
      @values    = values
    end
  end


  #  +value+
  #  +colour+
  #  +tip+
  #  +size+
  class DotValue
    include OWJSON
    def initialize(value = 0, colour = '', tip = nil)
      @value = value
      @colour = colour
      @tip = tip if tip
    end
  end
  # go to class LineBase for details
  class LineDot < LineBase ;end

  # go to class LineBase for details
  class Line < LineBase
    def initialize
      super
      @type      = "line"
    end
  end

  # go to class LineBase for details
  class LineHollow < LineBase
    def initialize
      super
      @type      = "line_hollow"
    end
  end

  #  +width+
  #  +color+
  #  +values+
  #  +dot_size+
  #  +text+
  #  +font_size+
  #  +fill_alpha+
  class AreaHollow
    include OWJSON
    def initialize(fill_alpha = 0.35, values = [])
      @type      = "area_hollow"
      set_fill_alpha  fill_alpha
      @values    = values
    end
  end

  #  +alpha+
  #  +colour+
  #  +values+
  #  +text+
  #  +font_size+
  class BarBase
    include OWJSON
    def initialize (values = [], text = '', size = '10px')
      @values = values
      @text = text
      @font__size = size
    end
    def set_key( text, size )
      @text = text
      @font__size = size
    end
    def append_value( v )
      @values << v
    end
    alias_method :<<, :append_value
  end

  # go to class BarBase for details
  class Bar < BarBase
    def initialize
      @type      = "bar"
    end
  end

  #  +top+
  #  +colour+
  #  +tip+
  class Value
    include OWJSON
    def initialize(top = 0, color = '', tip = nil)
      @top = top
      @colour = color
      @tip = tip
    end
  end
  class Bar3d < BarBase
    def initialize()
      @type      = "bar_3d"
    end
  end

  # go to class BarBase documentation for details
  class BarGlass < BarBase
    def initialize()
      @type      = "bar_glass"
    end
  end

  # go to class BarBase documentation for details
  #
  #  +offset+
  #  +colour+
  #  +outline_colour+
  class BarSketch < BarBase
    def initialize( colour = '#ff0000', outline_colour = '#00FF00', fun_factor = 5)
      @type      = "bar_sketch"
      set_colour( colour )
      set_outline_colour( outline_colour )
      @offset = fun_factor
    end
  end

  # go to class BarBase documentation for details
  class BarStack < BarBase
    include OWJSON
    def initialize
      super
      @type      = "bar_stack"
    end
    alias_method :append_stack, :append_value
  end

  # go to class Value documentation for details
  #
  #  +val+
  #  +color+
  class BarStackValue < Value
    include OWJSON
    def initialize(val, colour)
      @val = val
      @colour = colour
    end
  end

  #  +left+
  #  +right+
  class HBarValue
    include OWJSON
    def initialize( left, right )
      @left = left
      @right = right
    end
  end

  #  +colour+
  #  +text+
  #  +font_size+
  #  +values+
  class HBar
    include OWJSON
    def initialize(colour = "#9933CC", text = '', font_size = '10px')
      @type      = "hbar"
      @colour    = colour
      @text      = text
      set_font_size font_size
      @values    = []
    end

    # v suppostu be HBarValue class
    def append_value( v )
      @values << v
    end
    alias_method :<<, :append_value
  end

  # pie value
  #  +value+
  #  +text+
  class PieValue
    include OWJSON
    def initialize( value, text )
      @value  = value
      @text   = text
    end
  end


  #  +colours+
  #  +alpha+
  #  +border+
  #  +values+
  #  +animate+
  #  +start_angle+
  class Pie
    include OWJSON
    def initialize(colours = ["#d01f3c","#356aa0","#C79810"],
        alpha = 0.6,
        border = 2,
        values = [2,3, PieValue.new(6.5, "hello (6.5)")]
      )
      @type     = 'pie'
      @colours  = colours
      @alpha	= alpha
      @border	= border
      @values	= values
    end
  end


  # +shadow+
  # +stroke+
  # +colour+ text colour
  # +background+ background colour
  # +title+ title style
  # +body+ body style
  class Tooltip
    include OWJSON

    def set_title_style( style = '')
      @title = style
    end

    def set_body_style( style = '')
      @body = style
    end

    def set_proximity
      @mouse = 1
    end
    alias_method :proximity, :set_proximity

    def set_hover
      @mouse = 2
    end
    alias_method :hover, :set_hover
  end
end
