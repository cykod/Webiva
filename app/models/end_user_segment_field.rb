
class EndUserSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'User Fields',
      :domain_model_class => EndUser,
      :end_user_field => :id
    }
  end

  register_field :email, UserSegment::CoreType::StringType, :name => 'Email'
  register_field :gender, EndUserSegmentType::GenderType, :name => 'Gender'
  register_field :created, UserSegment::CoreType::DateTimeType, :field => :created_at, :name => 'Created'
  register_field :registered, UserSegment::CoreType::BooleanType, :name => 'Registered'
  register_field :activated, UserSegment::CoreType::BooleanType, :name => 'Activated'
  register_field :user_level, UserSegment::CoreType::NumberType, :name => 'User Level'
  register_field :dob, UserSegment::CoreType::DateTimeType, :name => 'DOB'
  register_field :last_name, UserSegment::CoreType::StringType, :name => 'Last Name'
  register_field :first_name, UserSegment::CoreType::StringType, :name => 'First Name'
  register_field :source, EndUserSegmentType::SourceType, :name => 'Source'
  register_field :lead_source, EndUserSegmentType::LeadSourceType, :name => 'Lead Source'
  register_field :registered_at, UserSegment::CoreType::DateTimeType, :name => 'Registered At'
  register_field :referrer, UserSegment::CoreType::StringType, :name => 'Referrer'
  register_field :username, UserSegment::CoreType::StringType, :name => 'Username'
  register_field :introduction, UserSegment::CoreType::StringType, :name => 'Introduction'
  register_field :suffix, UserSegment::CoreType::StringType, :name => 'Suffix'

end
