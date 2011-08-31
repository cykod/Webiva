
=begin rdoc
A user segment field type creates the scopes that the used segment filter.
The type determines the operations/functions availble to a field.

=end
class UserSegment::FieldType

  # A hash of all the operations for this type
  def self.user_segment_field_type_operations; {}; end

  # Whether or not this type has the operation
  def self.has_operation?(operation)
    self.user_segment_field_type_operations[operation.to_sym] ? true : false
  end

  # Registers operation to be applied to a field.
  #
  # name of the operation
  # list of arguments required by the operation
  #  an argument is name, type, options
  #  Ex: [['Format', :option, {:options => [['Day', 'day'], ['Weeks', 'week'] ...], :description => 'ago'}]
  #  argument options
  #  [:options]
  #    An array of select options
  #  [:description]
  #    The description used in the filter builder
  #  [:class]
  #    When the argument is type :model.  It uses this class to determine the select options.
  # Additional options
  # [:name]
  #   The name of the operation used in the operation builder list of operation options for a field.
  # [:description]
  #   A brief description used when creating the help
  # [:complex]
  #   When set to true this operation can not be combined with any other combined operation
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
  # supported types are :integer, :float, :double, :date, :datetime, :option, :boolean, :model, :array
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
        return Time.parse(value) unless value.is_a?(Array)
      rescue
      end
    when :option
      unless value.is_a?(Array)
        value = value.downcase if value.is_a?(String)
        value = opts[:options].find do |o|
          if o.is_a?(Array)
            o[1] == value
          else
            o == value
          end
        end

        return value[1] if value.is_a?(Array)
        return value
      end
    when :boolean
      return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      value = value.downcase if value.is_a?(String)
      return true if value == 1 || value == '1' || value == 'true'
      return false if value == 0 || value == '0' || value == 'false'
    when :model
      if value.is_a?(String) || value.is_a?(Integer)
        options = self.model_options(opts)
        value = value.to_i if options.size > 0 && options[0].is_a?(Array) && options[0][1].is_a?(Integer)
        if options[0].is_a?(Array)
          values = options.rassoc(value)
          return values[1] if values
        else
          return value if options.include?(value)
        end
      end
    when :array
      if value.is_a?(Array)
        options = self.model_options(opts)
        value.delete_if { |v| v == '' }
        value = value.collect { |v| v.to_i } if options.size > 0 && options[0].is_a?(Array) && options[0][1].is_a?(Integer)
        if options[0].is_a?(Array)
          value.each { |v| return nil unless options.rassoc(v) }
        else
          value.each { |v| return nil unless options.include?(v) }
        end
        return value
      end      
    end

    nil
  end

  # An array of the model options
  def self.model_options(opts={})
    opts[:class].select_options
  end

  # An array of the arguments converted to their correct types
  def self.convert_arguments(arguments, types, options)
    (0..arguments.length-1).collect do |idx|
      self.convert_to(arguments[idx], types[idx], options[idx])
    end
  end

  # A default method for displaying the data of a field
  def self.field_output(mdl, handler_data, field)
    info = UserSegment::FieldHandler.display_fields[field]
    return nil unless info

    display_field = info[:display_field]

    value = nil
    if handler_data.nil? # from end_user
      return nil unless mdl.respond_to?(display_field)
      value = mdl.send(display_field)
    else
      return nil unless handler_data[mdl.id]

      data = handler_data[mdl.id]
      if data.is_a?(Array) # group_by
        value = data.collect { |d| d.send(display_field) }.delete_if { |v| v.nil? }

        case info[:display_method]
        when 'max'
          value = value.max
        when 'min'
          value = value.min
        when 'sum'
          value = value.inject(0) { |a,b| a + b }
        when 'average'
          value = value.inject(0) { |a,b| a + b } / value.size
        when 'count'
          value = value.size
        else
          value = info[:handler].send(info[:display_method], value) if info[:display_method] && info[:handler].respond_to?(info[:display_method])
        end
      else # index_by
        value = data.send(display_field)
      end
    end

    if value.is_a?(Array)
      value = value.collect do |v|
        v = v.strftime(Configuration.datetime_format) if v.is_a?(Time)
        v = v.name if v.is_a?(DomainModel)
        v
      end

      value = value.map(&:to_s).reject(&:blank?).sort.uniq.join(', ')
    end

    value = value.strftime(Configuration.datetime_format) if value.is_a?(Time)
    value = value.strftime(Configuration.date_format) if value.is_a?(Date)
    value = value.name if value.is_a?(DomainModel)
    value = 'Yes'.t if value.is_a?(TrueClass)
    value = 'No'.t if value.is_a?(FalseClass)
    value
  end
end
