
=begin rdoc
A user segment field handler is used to create a handler for :user_segment :fields.
Basically it is a container for all the fields that can be queried agains a DomainModel.

from EndUserSegmentField:

  def self.user_segment_fields_handler_info
    {
      :name => 'User Fields',
      :domain_model_class => EndUser,
      :end_user_field => :id
    }
  end

The handler info must contain the :domain_model_class.
The :end_user_field by default is assumed to be :end_user_id.

=end
class UserSegment::FieldHandler
  include HandlerActions

  # A hash containing all the registered fields.
  def self.user_segment_fields; {}; end

  # Where or not the field exists in the handler.
  def self.has_field?(field)
    self.user_segment_fields[field.to_sym] ? true : false
  end

  # Used to register fields for the segment filter.
  #
  # field is the name of the filter field.
  #
  # type is the UserSegment::FieldType of the field
  #
  # options
  #
  # [:name]
  #   the display name of the field, by default humanizes the field
  # [:builder_name]
  #   the name to use inside the filter builder
  # [:field]
  #   the actual field in the model, by default uses field
  # [:display_field]
  #   the field in the model to display, by default uses field
  # [:search_only]
  #   when set to true the field is not available is the UserSegment::FieldHandler.display_fields
  # [:display_method]
  #   default method used to transform the handler data into output
  # [:display_methods]
  #   an optional array of methods for display the fields data
  # [:sortable]
  #   when set to true the field is available is the UserSegment::FieldHandler.sortable_fields
  # [:sort_method]
  #   default method used when sorting on this field
  # [:sort_methods]
  #   an optional array of methods for sorting on this field
  # [:scope]
  #   an optional scope or set of conditions to be applied to the field.
  def self.register_field(field, type, options={})
    fields = self.user_segment_fields

    fields[field.to_sym] = options.merge(:type => type, :handler => self)
    fields[field.to_sym][:name] ||= field.to_s.humanize
    fields[field.to_sym][:builder_name] ||= fields[field.to_sym][:name]
    fields[field.to_sym][:field] ||= field.to_sym
    fields[field.to_sym][:display_field] ||= fields[field.to_sym][:field]

    sing = class << self; self; end
    sing.send :define_method, :user_segment_fields do 
      fields
    end 
  end

  # An array of all the :user_segment :fields handlers info.
  def self.handlers
    key = 'user_segment_field_handlers'
    return DataCache.local_cache(key) if DataCache.local_cache(key)

    handlers = ([ self.get_handler_info(:user_segment, :fields, 'end_user_segment_field'),
                  self.get_handler_info(:user_segment, :fields, 'end_user_action_segment_field'),
                  self.get_handler_info(:user_segment, :fields, 'end_user_tag_segment_field')] +
                self.get_handler_info(:user_segment, :fields) +
                self.custom_content_model_handlers).uniq

    DataCache.put_local_cache(key, handlers)
  end

  def self.custom_content_model_handlers
    ContentModelField.find(:all, :conditions => {:field_type => 'belongs_to'}).delete_if { |f| f.relation_class != EndUser }.collect do |field|
      cls = ContentModelSegmentField.create_custom_field_handler_class(field)
      info = cls.user_segment_fields_handler_info
      info[:class] = cls
      info[:identifier] = field.content_model.table_name
      info
    end
  end

  # A hash of all the fields that can be sorted on
  def self.sortable_fields(opts={})
    key = 'user_segment_sortable_fields_' + opts.to_s
    return DataCache.local_cache(key) if DataCache.local_cache(key)

    fields = {}
    self.handlers.each do |handler|
      next unless handler[:class].respond_to?(:sort_scope)
      next if opts[:end_user_only] && handler[:domain_model_class] != EndUser
      handler[:class].user_segment_fields.each do |field, info|
        next unless info[:sortable]
        next if fields[field]
        fields[field] = info

        if info[:sort_methods]
          info[:sort_methods].each do |name, method|
            field_method = "#{field}_#{method}".to_sym
            fields[field_method] = info.merge(:base_field => field, :sort_method => method, :name => name) unless fields[field_method]
          end
        end
      end
    end

    DataCache.put_local_cache(key, fields)
  end

  # A hash of all the fields that can be displayed
  def self.display_fields(opts={})
    key = 'user_segment_display_fields_' + opts.to_s
    return DataCache.local_cache(key) if DataCache.local_cache(key)

    fields = {}
    self.handlers.each do |handler|
      next unless handler[:class].respond_to?(:field_output)
      handler[:class].user_segment_fields.each do |field, info|
        next if info[:search_only]
        next if fields[field]
        fields[field] = info

        if info[:display_methods]
          info[:display_methods].each do |name, method|
            field_method = "#{field}_#{method}".to_sym
            fields[field_method] = info.merge(:base_field => field, :display_method => method, :name => name) unless fields[field_method]
          end
        end
      end
    end

    DataCache.put_local_cache(key, fields)
  end

  # A default method for all handlers to display the heading
  def self.field_heading(field)
    info = self.display_fields[field.to_sym]
    info = self.sortable_fields[field.to_sym] unless info
    return '' unless info
    info[:name]
  end
end
