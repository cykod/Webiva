
class EndUserActionSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'End User Action Segment Fields',
      :domain_model_class => EndUserAction
    }
  end

  register_field :renderer, UserSegment::CoreType::StringType
  register_field :action, UserSegment::CoreType::StringType
  register_field :created, UserSegment::CoreType::DateTimeType, :field => :created_at
  register_field :occurred, UserSegment::CoreType::DateTimeType, :field => :action_at

end
