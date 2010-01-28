

class SiteWidget < DomainModel #:nodoc:all

  cached_content :update_list => 'EditorWidget'

  has_many :editor_widgets, :dependent => :destroy

  serialize :data

  attr_accessor :widget_identifier

  validates_presence_of :module, :widget, :title
  attr_protected :module,:widget

  include SiteAuthorizationEngine::Target
  access_control :view_permission

  validate :widget_options_validation # From WidgetMethods

  include Dashboard::WidgetMethods

  def self.create_widget(mod,widget,options={ })
    returning site_widget=self.new(options) do
      site_widget.module = mod
      site_widget.widget = widget
      site_widget.save
    end
  end

  def create_user_widget(user)
    self.editor_widgets.create(:end_user_id => user.id, 
                               :module => self.module,
                               :widget => self.widget,
                               :column => self.column, 
                               :position => EditorWidget.next_widget_position(user,self.column))
  end
 
  def before_validation_on_create
    unless self.widget_identifier.blank?
      self.module, self.widget = self.widget_identifier.split(":")
    end
  end


  def self.core_widgets 
    widgets =[]
    Dir.glob("#{RAILS_ROOT}/app/models/dashboard/[a-z0-9\-_]*_widget.rb") do |file|
      if file =~ /\/([a-z0-9\-_]+)_widget.rb$/
        widget_class = "Dashboard::#{$1.camelcase}Widget"
        cls = widget_class.constantize
        widgets += cls.available_widgets if cls.respond_to?(:available_widgets)
      end
    end
    widgets
  end

  def self.handler_widgets
    widgets = []
    get_handler_info(:webiva,:widget).each do |handler|
      widgets += handler[:class].available_widgets if handler[:class].respond_to?(:available_widgets)
    end
    widgets
  end

  def self.all_widgets
    self.core_widgets + self.handler_widgets
  end

  def site_widget; self; end

  def self.widget_from_identifier(identifier)
    widget_module, widget_name = identifier.split(":")
    widget = self.all_widgets.detect() {  |widget| widget[0] == widget_module && widget[1] == widget_name }
  end

  def self.widget_options_from_identifier(identifier)
    widget = widget_from_identifier(identifier)
    if widget
      widget_options_class(widget[0],widget[1]).new({ })
    else
      nil
    end
  end

  def self.widget_options(user=nil)
    all_widgets.map do |widget|
      if !user || (!widget[2][:permission] ||  user.has_role?(widget[2][:permission]))
        [widget[2][:name],widget[0] + ":" + widget[1]]
      else 
        nil
      end
    end.compact
  end
end
