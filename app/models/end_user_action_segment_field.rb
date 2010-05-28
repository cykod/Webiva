
class EndUserActionSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'End User Action Segment Fields',
      :domain_model_class => EndUserAction
    }
  end

  register_field :user_action, EndUserActionSegmentType::UserActionType, :field => [:renderer, :action], :name => 'User Actions'
  register_field :action, EndUserActionSegmentType::ActionType, :name => 'User Actions: Action'
  register_field :renderer, EndUserActionSegmentType::RendererType, :name => 'User Actions: Renderer'
  register_field :created, UserSegment::CoreType::DateTimeType, :field => :created_at, :name => 'User Actions: Created'
  register_field :occurred, UserSegment::CoreType::DateTimeType, :field => :action_at, :name => 'User Actions: Occurred'

end
