
class EndUserActionSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'User Action Fields',
      :domain_model_class => EndUserAction
    }
  end

  register_field :user_action, EndUserActionSegmentType::UserActionType, :field => [:renderer, :action], :name => 'User Actions', :display_field => :description, :sortable => true
  register_field :action, EndUserActionSegmentType::ActionType, :name => 'User Actions: Action', :sortable => true
  register_field :renderer, EndUserActionSegmentType::RendererType, :name => 'User Actions: Renderer', :sortable => true
  register_field :created, UserSegment::CoreType::DateTimeType, :field => :created_at, :name => 'User Actions: Created'
  register_field :occurred, UserSegment::CoreType::DateTimeType, :field => :action_at, :name => 'User Actions: Occurred', :sortable => true

  def self.sort_scope(order_by, direction)
    if order_by.to_sym == :user_action
      EndUserAction.scoped :order => "renderer #{direction}, action #{direction}"
    else
      field = self.user_segment_fields[order_by.to_sym][:field]
      EndUserAction.scoped :order => "#{field} #{direction}"
    end
  end

  def self.field_heading(field)
    self.user_segment_fields[field][:name]
  end

  def self.get_handler_data(ids, fields)
    EndUserAction.find(:all, :conditions => {:end_user_id => ids}).group_by(&:end_user_id)
  end

  def self.field_output(user, handler_data, field)
    return nil unless handler_data[user.id]

    display_field = self.user_segment_fields[field][:display_field]
    handler_data[user.id].collect do |item|
      value = item.send(display_field)
      value = value.strftime(DEFAULT_DATETIME_FORMAT.t) if value.is_a?(Time)
      value
    end.join(', ')
  end
end
