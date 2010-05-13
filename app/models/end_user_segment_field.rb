
class EndUserSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'End User Segment Fields',
      :domain_model_class => EndUser,
      :end_user_field => :id
    }
  end

  register_field :email, UserSegment::CoreType::StringType
  register_field :gender, UserSegment::CoreType::StringType
  register_field :created, UserSegment::CoreType::DateTimeType, :field => :created_at
  register_field :registered, UserSegment::CoreType::BooleanType
  register_field :activated, UserSegment::CoreType::BooleanType
  register_field :id, UserSegment::CoreType::NumberType

end
