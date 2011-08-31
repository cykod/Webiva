
class EndUserSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'User Fields',
      :domain_model_class => EndUser,
      :end_user_field => :id
    }
  end

  register_field :email, UserSegment::CoreType::StringType, :name => 'Email', :sortable => true, :search_only => true
  register_field :gender, EndUserSegmentType::GenderType, :name => 'Gender', :sortable => true
  register_field :created, UserSegment::CoreType::DateTimeType, :field => :created_at, :name => 'Created', :sortable => true, :builder_name => 'Created when?'
  register_field :registered, UserSegment::CoreType::BooleanType, :name => 'Registered', :sortable => true, :builder_name => 'Show registered accounts?'
  register_field :activated, UserSegment::CoreType::BooleanType, :name => 'Activated', :sortable => true, :builder_name => 'Show activated accounts?'

  register_field :acknowledged, UserSegment::CoreType::BooleanType, :name => 'Acknowledged', :sortable => true, :builder_name => 'Show acknowledged accounts?'
  register_field :user_level, EndUserSegmentType::UserLevelType, :name => 'User Level', :sortable => true
  register_field :user_value, UserSegment::CoreType::SimpleNumberType, :field => :value, :name => 'User Value', :sortable => true
  register_field :dob, UserSegment::CoreType::DateTimeType, :name => 'DOB', :sortable => true
  register_field :last_name, UserSegment::CoreType::StringType, :name => 'Last Name', :sortable => true
  register_field :first_name, UserSegment::CoreType::StringType, :name => 'First Name', :sortable => true
  register_field :source, EndUserSegmentType::SourceType, :name => 'Origin', :sortable => true, :display_field => 'source_display'
  register_field :user_class_id, EndUserSegmentType::UserClassType, :name => 'User Profile', :sortable => true, :display_field => :user_class
  register_field :lead_source, EndUserSegmentType::LeadSourceType, :name => 'Lead Source', :sortable => true
  register_field :registered_at, UserSegment::CoreType::DateTimeType, :name => 'Registered At', :sortable => true
  register_field :referrer, UserSegment::CoreType::StringType, :name => 'Referrer', :sortable => true
  register_field :username, UserSegment::CoreType::StringType, :name => 'Username', :sortable => true
  register_field :introduction, UserSegment::CoreType::StringType, :name => 'Introduction', :sortable => true
  register_field :suffix, UserSegment::CoreType::StringType, :name => 'Suffix', :sortable => true
  register_field :cell_phone, UserSegment::CoreType::StringType, :name => 'Cell Phone', :sortable => true
  register_field :profile, EndUserSegmentType::UserClassType, :field => :user_class_id, :name => 'User Profile', :sortable => true

  def self.sort_scope(order_by, direction)
    field = self.user_segment_fields[order_by.to_sym][:field]
    EndUser.scoped :order => "end_users.#{field} #{direction}"
  end

  def self.get_handler_data(ids, fields)
  end

  def self.field_output(user, handler_data, field)
    if field == :profile
      user.user_class.name
    elsif field == :user_level
      user.user_level_display
    else
      UserSegment::FieldType.field_output(user, handler_data, field)
    end
  end
end
