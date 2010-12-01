
class ContentModelSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => self.content_model.name,
      :domain_model_class => self.content_model.content_model,
      :end_user_field => self.end_user_field
    }
  end

  def self.sing
    class << self; self; end
  end

  class OptionsType < UserSegment::FieldType
    def self.is(cls, group_field, field, string)
      cls.scoped(:conditions => ["#{field} = ?", string])
    end

    def self.create_type(options)
      cls = Class.new OptionsType
      cls.register_operation :is, [['Option', :option, {:options => options}]]
      cls
    end
  end

  class MultiOptionsType < UserSegment::FieldType
    def self.is(cls, group_field, field, string)
      cls.scoped(:conditions => ["#{field} like ?", "%#{string}%"])
    end

    def self.create_type(options)
      cls = Class.new MultiOptionsType
      cls.register_operation :is, [['Option', :option, {:options => options}]]
      cls
    end
  end

  def self.create_custom_field_handler_class(content_model_field)
    content_model = content_model_field.content_model
    cls = Class.new ContentModelSegmentField
    cls.sing.send :define_method, :content_model do
      content_model
    end

    cls.sing.send :define_method, :end_user_field do
      content_model_field.field.to_sym
    end

    content_model.content_model_fields.each do |field|
      case field.field_type
      when 'string'
        cls.register_field "#{content_model.table_name}_#{field.field}", UserSegment::CoreType::StringType, :field => field.field, :name => field.name
      when 'email'
        cls.register_field "#{content_model.table_name}_#{field.field}", UserSegment::CoreType::StringType, :field => field.field, :name => field.name
      when 'boolean'
        cls.register_field "#{content_model.table_name}_#{field.field}", UserSegment::CoreType::BooleanType, :field => field.field, :name => field.name
      when 'date'
        cls.register_field "#{content_model.table_name}_#{field.field}", UserSegment::CoreType::DateTimeType, :field => field.field, :name => field.name
      when 'datetime'
        cls.register_field "#{content_model.table_name}_#{field.field}", UserSegment::CoreType::DateTimeType, :field => field.field, :name => field.name
      when 'integer'
        cls.register_field "#{content_model.table_name}_#{field.field}", UserSegment::CoreType::NumberType, :field => field.field, :name => field.name
      when 'currency'
        cls.register_field "#{content_model.table_name}_#{field.field}", UserSegment::CoreType::NumberType, :field => field.field, :name => field.name
      when 'options'
        type = ContentModelSegmentField::OptionsType.create_type field.module_class.available_options.clone
        cls.register_field "#{content_model.table_name}_#{field.field}", type, :field => field.field, :name => field.name
      when 'multi_select'
        type = ContentModelSegmentField::MultiOptionsType.create_type field.module_class.available_options.clone
        cls.register_field "#{content_model.table_name}_#{field.field}", type, :field => field.field, :name => field.name
      when 'us_state'
        type = ContentModelSegmentField::OptionsType.create_type Content::CoreField::UsStateField.states_select_options
        cls.register_field "#{content_model.table_name}_#{field.field}", type, :field => field.field, :name => field.name
      end
    end

    cls
  end

  def self.field_heading(field)
    self.content_model.name + ' - ' + self.user_segment_fields[field][:name]
  end

  def self.get_handler_data(ids, fields)
    self.content_model.content_model.find(:all, :conditions => {self.end_user_field => ids}).group_by(&self.end_user_field)
  end

  def self.field_output(user, handler_data, field)
    info = UserSegment::FieldHandler.display_fields[field]
    return unless info && handler_data[user.id]
    display_field = info[:display_field]
    handler_data[user.id].collect do |data|
      self.content_model.field(display_field).content_display(data, :excerpt)
    end.join(', ')
  end
end
