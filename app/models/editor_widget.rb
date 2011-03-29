

class EditorWidget < DomainModel

  cached_content

  belongs_to :site_widget
  belongs_to :end_user

  validates_presence_of :module
  validates_presence_of :widget

  serialize :data

  attr_accessor :widget_identifier

  validate :widget_options_validation # From WidgetMethods
  
  before_validation(:on => :create) { self.module, self.widget = self.widget_identifier.split(":") unless self.widget_identifier.blank? }

  after_create :update_editor_widget_positions

  scope :with_widget, where('site_widget_id IS NOT NULL')
  def self.for_column(column); self.where(:column => column); end
  def self.for_user(user)
    user = user.id if user.is_a?(EndUser)
    self.where(:end_user_id => user)
  end

  def update_editor_widget_positions
    EditorWidget.update_all('`position`=`position`+1',['`column`=? AND `end_user_id`=? AND `position` >= ?',self.column,self.end_user_id,self.position])
  end

  include Dashboard::WidgetMethods

  def title
    if self.site_widget
      self.site_widget.title
    else
      self[:title]
    end
  end

  def required?(user)
    if user.has_role?(:editor_website_configuration)
      false
    else
      self.site_widget.required?
    end
  end

  def view_permission_granted?(user)
    if self.site_widget
      self.site_widget.view_permission_granted?(user)
    else
      true
    end
  end

  def permission?(user)
    info =  self.widget_class.widget_information(self.widget)
    if !info
      false
    elsif permission =  info[:permission]
      user.has_role?(permission)
    else
      true
    end
  end

  def editable?(user)
    self.site_widget ? false : true
  end

  def widget_instance
    @widget_instance ||= self.widget_class.new(self.options,self)
  end
  
  def render_widget(controller,first = false)
    self.widget_instance.first = first
    self.widget_instance.controller_render_widget(self.widget,controller)
  end

  def includes
    self.widget_instance.includes
  end

  def icon
    self.widget_instance.icon || "content_general_icon.png"
  end

  def output
    self.widget_instance.output
  end

  def title_link
    self.widget_instance.title_link
  end

  def self.next_widget_position(user,column) #:nodoc:
    (EditorWidget.for_user(user).for_column(column).maximum(:position) || -1) + 1
  end

  def self.site_widgets(user)  #:nodoc:
    EditorWidget.for_user(user).with_widget.all
  end

 def self.user_widgets(user)  #:nodoc:
    EditorWidget.for_user(user).all
  end


 def self.assemble_widgets(user) #:nodoc:
   # return from the cache 
   # turn into columns of actual objects
   no_rebuild = cache_fetch_list("UserWidgets:#{user.id}")
   if !no_rebuild
     editor_widgets = EditorWidget.site_widgets(user)
     editor_widgets.select do |widget|
       if widget.site_widget && !widget.view_permission_granted?(user)
         widget.destroy
         false
       else
         true
       end
     end
     existing_widgets = editor_widgets.index_by(&:site_widget_id)
     SiteWidget.order('weight').all.each do |widget|
       if widget.view_permission_granted?(user)
         if(!existing_widgets[widget.id])
           widget.create_user_widget(user)
         end
       end
     end
     cache_put_list("UserWidgets:#{user.id}",Time.now)
   end

   all_widgets = EditorWidget.for_user(user).order('position').includes(:site_widget).all
   columns = [[],[],[] ]
   all_widgets.each do |widget|
     if  widget.permission?(user)
       columns[widget.column] << widget
     end
   end
   columns

 end

 def self.update_widget_positions(user,columns)
   widgets = EditorWidget.user_widgets(user).index_by(&:id)
   columns.each_with_index do |col,idx|
     if(col)
       col.each_with_index do |widget_id,position|
         if widgets[widget_id.to_i]
           widgets[widget_id.to_i].update_attributes(:column => idx,:position => position )
         end
       end
     end
   end
 end

    
end
