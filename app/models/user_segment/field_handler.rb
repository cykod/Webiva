
class UserSegment::FieldHandler
  include HandlerActions

  def self.user_segment_fields; {}; end

  def self.has_field?(field)
    self.user_segment_fields[field.to_sym] ? true : false
  end
    
  def self.register_field(field, type, options={})
    fields = self.user_segment_fields

    fields[field.to_sym] = options.merge(:type => type, :handler => self)
    fields[field.to_sym][:name] ||= field.to_s.humanize
    fields[field.to_sym][:field] ||= field.to_sym
    fields[field.to_sym][:display_field] ||= fields[field.to_sym][:field]

    sing = class << self; self; end
    sing.send :define_method, :user_segment_fields do 
      fields
    end 
  end

  def self.handlers
    ([ self.get_handler_info(:user_segment, :fields, 'end_user_segment_field'),
       self.get_handler_info(:user_segment, :fields, 'end_user_action_segment_field'),
       self.get_handler_info(:user_segment, :fields, 'end_user_tag_segment_field')] +
       self.get_handler_info(:user_segment, :fields)).uniq
  end

  def self.sortable_fields(opts={})
    fields = {}
    self.handlers.each do |handler|
      next unless handler[:class].respond_to?(:order_options)
      next if opts[:end_user_only] && handler[:domain_model_class] != EndUser
      handler[:class].user_segment_fields.each do |field, info|
        next unless info[:sortable]
        next if fields[field]
        fields[field] = info
      end
    end
    fields
  end

  def self.display_fields(opts={})
    fields = {}
    self.handlers.each do |handler|
      next unless handler[:class].respond_to?(:field_output)
      handler[:class].user_segment_fields.each do |field, info|
        next if info[:search_only]
        next if fields[field]
        fields[field] = info
      end
    end
    fields
  end
end
