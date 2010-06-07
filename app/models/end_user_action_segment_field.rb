
class EndUserActionSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'User Action Fields',
      :domain_model_class => EndUserAction
    }
  end

  register_field :num_actions, UserSegment::CoreType::CountType, :field => :end_user_id, :name => '# Actions', :display_method => 'count', :sort_method => 'count', :sortable => true
  register_field :user_action, EndUserActionSegmentType::UserActionType, :field => [:renderer, :action], :name => 'User Actions', :display_field => :description, :sortable => true, :display_field => :description
  register_field :action, EndUserActionSegmentType::ActionType, :name => 'User Actions: Action', :sortable => true
  register_field :renderer, EndUserActionSegmentType::RendererType, :name => 'User Actions: Renderer', :sortable => true
  register_field :created, UserSegment::CoreType::DateTimeType, :field => :created_at, :name => 'User Actions: Created'
  register_field :occurred, UserSegment::CoreType::DateTimeType, :field => :action_at, :name => 'User Actions: Occurred', :sortable => true

  def self.sort_scope(order_by, direction)
     info = UserSegment::FieldHandler.sortable_fields[order_by.to_sym]

    if order_by.to_sym == :user_action
      EndUserAction.scoped :order => "renderer #{direction}, action #{direction}"
    elsif order_by.to_sym == :num_actions
      sort_method = info[:sort_method]
      field = info[:field]
      EndUserAction.scoped(:select => "end_user_id, #{sort_method}(#{field}) as #{field}_#{sort_method}", :group => :end_user_id, :order => "#{field}_#{sort_method} #{direction}")
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
    UserSegment::FieldType.field_output(user, handler_data, field)
  end
end
