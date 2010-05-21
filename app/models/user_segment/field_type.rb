
class UserSegment::FieldType

  def self.user_segment_field_type_operations; {}; end

  def self.has_operation?(operation)
    self.user_segment_field_type_operations[operation.to_sym] ? true : false
  end
    
  def self.register_operation(operation, args=[], options={})
    operations = self.user_segment_field_type_operations

    arguments = []
    argument_names = []
    argument_options = []
    args.each do |arg|
      if arg.is_a?(Array)
        name = arg[0]
        type = arg[1].to_sym
        opts = arg[2] || {}
      else
        type = arg
        name = type.to_s.humanize
        opts = {}
      end

      arguments << type.to_sym
      argument_names << name
      argument_options << opts
    end

    
    operations[operation.to_sym] = options.merge(:arguments => arguments, :argument_names => argument_names, :argument_options => argument_options)
    operations[operation.to_sym][:name] ||= operation.to_s.humanize

    sing = class << self; self; end
    sing.send :define_method, :user_segment_field_type_operations do 
      operations
    end 
  end

  # converts a string to the correct type
  # supported types are :integer, :float, :double, :date, :datetime, :option, :boolean
  def self.convert_to(value, type, opts={})
    return value if value.nil?

    case type
    when :integer
      return value.to_i if value.is_a?(Integer) || value =~ /^\d+$/
    when :float, :double
      return value.to_f if value.is_a?(Numeric) || value =~ /^(\d+|\.\d+|\d+\.\d+)$/
    when :string
      return value if value.is_a?(String)
    when :date, :datetime
      begin
        return value if value.is_a?(Time)
        return Time.parse(value)
      rescue
      end
    when :option
      value = opts[:options].find do |o|
        if o.is_a?(Array)
          o[1].downcase == value.downcase
        else
          o.downcase == value.downcase
        end
      end

      return value[1] if value.is_a?(Array)
      return value if value
    when :boolean
      return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      value = value.downcase if value.is_a?(String)
      return true if value == 1 || value == '1' || value == 'true'
      return false if value == 0 || value == '0' || value == 'false'
    end

    nil
  end

  def self.convert_arguments(arguments, types, options)
    (0..arguments.length-1).collect do |idx|
      self.convert_to(arguments[idx], types[idx], options[idx])
    end
  end
end
