
class EndUserSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'End User Segment Fields',
      :domain_model_class => EndUser,
      :end_user_field => :id
    }
  end

  register_field :email, UserSegment::CoreType::StringType, :name => 'Users: Email'
  register_field :gender, EndUserSegmentType::GenderType, :name => 'Users: Gender'
  register_field :created, UserSegment::CoreType::DateTimeType, :field => :created_at, :name => 'Users: Created'
  register_field :registered, UserSegment::CoreType::BooleanType, :name => 'Users: Registered'
  register_field :activated, UserSegment::CoreType::BooleanType, :name => 'Users: Activated'
  register_field :user_level, UserSegment::CoreType::NumberType, :name => 'Users: User Level'
  register_field :dob, UserSegment::CoreType::DateTimeType, :name => 'Users: DOB'
  register_field :last_name, UserSegment::CoreType::StringType, :name => 'Users: Last Name'
  register_field :first_name, UserSegment::CoreType::StringType, :name => 'Users: First Name'
  register_field :source, EndUserSegmentType::SourceType, :name => 'Users: Source'
  register_field :lead_source, EndUserSegmentType::LeadSourceType, :name => 'Users: Lead Source'
  register_field :registered_at, UserSegment::CoreType::DateTimeType, :name => 'Users: Registered At'
  register_field :referrer, UserSegment::CoreType::StringType, :name => 'Users: Referrer'
  register_field :username, UserSegment::CoreType::StringType, :name => 'Users: Username'
  register_field :introduction, UserSegment::CoreType::StringType, :name => 'Users: Introduction'
  register_field :suffix, UserSegment::CoreType::StringType, :name => 'Users: Suffix'

end
