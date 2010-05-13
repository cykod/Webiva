
class UserSegment::FieldType

  def self.user_segment_field_type_operations
    @user_segment_field_type_operations ||= {}
  end

  def self.has_operation?(operation)
    self.user_segment_field_type_operations[operation.to_sym] ? true : false
  end
    
  def self.register_operation(operation, args=[], options={})
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

    name = options[:name] || operation.to_s.humanize

    self.user_segment_field_type_operations[operation.to_sym] = options.merge(:name => name, :arguments => arguments, :argument_names => argument_names, :argument_options => argument_options)
  end

  # converts a string to the correct type
  # supported types are :integer, :float, :double, :date, :datetime, :option, :boolean
  def self.convert_to(value, type, opts={})
    case type
    when :integer
      return value.to_i if value.is_a?(Integer) || value =~ /^\d+$/
    when :float, :double
      return value.to_f if value.is_a?(Numeric) || value =~ /^(\d+|\.\d+|\d+\.\d+)$/
    when :string
      return value
    when :date, :datetime
      begin
        return value if value.is_a?(::Time)
        return Time.parse(value)
      rescue
      end
    when :option
      value = opts[:options].find { |o| o.downcase == value.downcase }
      return value if value
    when :boolean
      return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      return true if value == '1' || value.downcase == 'true'
      return false if value == '0' || value.downcase == 'false'
    end

    nil
  end

  def self.convert_arguments(arguments, types, options)
    (0..arguments.length-1).collect do |idx|
      self.convert_to(arguments[idx], types[idx], options[idx])
    end
  end
end
