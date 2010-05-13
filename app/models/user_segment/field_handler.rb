
class UserSegment::FieldHandler

  def self.user_segment_fields; {}; end

  def self.has_field?(field)
    self.user_segment_fields[field.to_sym] ? true : false
  end
    
  def self.register_field(field, type, options={})
    fields = self.user_segment_fields

    fields[field.to_sym] = options.merge(:type => type)
    fields[field.to_sym][:name] ||= field.to_s.humanize
    fields[field.to_sym][:field] ||= field.to_sym

    sing = class << self; self; end
    sing.send :define_method, :user_segment_fields do 
      fields
    end 
  end
end
