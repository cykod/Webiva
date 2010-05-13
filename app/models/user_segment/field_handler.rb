
class UserSegment::FieldHandler

  def self.user_segment_fields
    @user_segment_fields ||= {}
  end

  def self.has_field?(field)
    self.user_segment_fields[field.to_sym] ? true : false
  end
    
  def self.register_field(field, type, options={})
    self.user_segment_fields[field.to_sym] = options.merge(:type => type)
    self.user_segment_fields[field.to_sym][:name] ||= field.to_s.humanize
    self.user_segment_fields[field.to_sym][:field] ||= field.to_sym
  end
end
