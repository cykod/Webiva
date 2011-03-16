
class WebformFormResultSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'Webform Fields',
      :domain_model_class => WebformFormResult,
      :end_user_field => :end_user_id
    }
  end

  class WebformType < UserSegment::FieldType
    register_operation :is, [['Webform', :model, {:class => WebformForm}]]

    def self.is(cls, group_field, field, id)
      cls.scoped(:conditions => ["#{field} = ?", id])
    end
  end

  register_field :webform, WebformType, :field => :webform_form_id, :name => 'Webform', :display_field => :webform_name, :partial => '/webform/user_segment/field'
  register_field :webform_posted_at, UserSegment::CoreType::DateTimeType, :field => :posted_at, :name => 'Webform Posted At', :sortable => true, :display_method => 'max'
  register_field :webform_reviewed, UserSegment::CoreType::BooleanType, :field => :reviewed, :name => 'Webform Reviewed', :partial => '/webform/user_segment/field'
  # register_field :webform_data, UserSegment::CoreType::StringType, :field => :data, :name => 'Webform Results'

  def self.sort_scope(order_by, direction)
     info = UserSegment::FieldHandler.sortable_fields[order_by.to_sym]
    field = self.user_segment_fields[order_by.to_sym][:field]
    WebformFormResult.scoped :order => "#{field} #{direction}"
  end

  def self.field_heading(field)
    self.user_segment_fields[field][:name]
  end

  def self.get_handler_data(ids, fields)
    WebformFormResult.find(:all, :conditions => {:end_user_id => ids}, :include => :webform_form).group_by(&:end_user_id)
  end

  def self.field_output(user, handler_data, field)
    UserSegment::FieldType.field_output(user, handler_data, field)
  end
end
