
class UserSegment::Field < HashModel
  attributes :field => nil, :operation => nil, :arguments => [], :child => nil

  validates_presence_of :field
  validates_presence_of :operation

  def strict?; true; end

  def failure_reasons; @failure_reasons || []; end

  def add_error(attr, message)
    @failure_reasons ||= []

    self.errors.add(attr, message) unless attr == :complex

    case attr
    when :field
      @failure_reasons << "'#{self.field}' is an invalid field"
    when :operation
      @failure_reasons << "'#{self.operation}' is an invalid function on '#{self.field}'"
    when :complex
      self.errors.add(:operation, 'is invalid')
      @failure_reasons << "Too many complex functions combined. Move '#{self.field}.#{self.operation}()' to a new line."
    when :arguments
      @failure_reasons << "Arguments #{message} for '#{self.field}.#{self.operation}()'"
    when :child
      @failure_reasons = @failure_reasons + self.child_field.failure_reasons
    end
  end

  def validate
    unless self.field.blank?
      
      self.add_error(:field, 'invalid field') unless self.handler
    end

    unless self.handler.nil? || self.operation.blank?
      self.add_error(:operation, 'invalid operation') if ! self.type_class || ! self.type_class.has_operation?(self.operation)

      if self.operation_info
        self.add_error(:arguments, 'are missing') if self.arguments.empty? && ! self.operation_arguments.empty?

        unless self.arguments.empty?
          self.add_error(:arguments, 'are incorrect') unless self.arguments.size == self.operation_arguments.size
          self.add_error(:arguments, 'are invalid') if self.arguments.size == self.operation_arguments.size && ! self.valid_arguments?
        end
      end
    end

    if self.child && self.child_field
      if self.child_field.valid?
        is_complex = self.complex_operation
        c = self.child_field
        while c
          if c.complex_operation
            if is_complex
              self.add_error(:complex, 'too many')
            end
            is_complex = true
          end
          c = c.child_field
        end
      else
        self.add_error(:child, 'is invalid')
      end
    end
  end

  def count
    @count ||= self.get_scope.count
  end

  def end_user_ids(ids=nil)
    scope = self.get_scope
    scope = scope.scoped(:conditions => {self.end_user_field  => ids}) if ids
    scope = scope.scoped(:select => self.end_user_field)
    scope.find(:all).collect &self.end_user_field
  end

  def get_default_scope(scope=nil)
    scope ||= self.domain_model_class
    base_scope = self.handler_class.user_segment_fields[self.field.to_sym][:scope]
    scope = scope.scoped base_scope if base_scope
    scope
  end

  def get_scope(scope=nil)
    return @scope if @scope
    @scope = self.type_class.send(self.operation, self.get_default_scope(scope), self.end_user_field, self.model_field, *self.converted_arguments)
    @scope = self.child_field.get_scope(@scope) if self.child_field
    @scope
  end

  def converted_arguments
    @converted_arguments ||= UserSegment::FieldType.convert_arguments(self.arguments, self.operation_arguments, self.operation_argument_options) if self.operation_arguments
  end

  def valid_arguments?
    return false unless self.converted_arguments
    self.converted_arguments.each { |arg| return false if arg.nil? }
    true
  end

  def operation_arguments
    self.operation_info[:arguments] if self.operation_info
  end

  def operation_argument_options
    self.operation_info[:argument_options] if self.operation_info
  end

  def operation_argument_names
    self.operation_info[:argument_names] if self.operation_info
  end

  def operation_info
    @operation_info ||= self.type_class.user_segment_field_type_operations[self.operation.to_sym] if self.operation && self.type_class
  end

  def complex_operation
    self.operation_info[:complex] if self.operation_info
  end

  def builder_name
    self.handler_class.user_segment_fields[self.field.to_sym][:builder_name] if self.handler_class && self.handler_class.user_segment_fields && self.handler_class.user_segment_fields[self.field.to_sym]
  end

  def description
    raise self.handler_class.user_segment_fields[self.field.to_sym].inspect
    self.handler_class.user_segment_fields[self.field.to_sym][:description] if self.handler_class && self.handler_class.user_segment_fields && self.handler_class.user_segment_fields[self.field.to_sym]
  end

  def type_class
    @type_class ||= self.handler_class.user_segment_fields[self.field.to_sym][:type] if self.handler_class && self.handler_class.user_segment_fields && self.handler_class.user_segment_fields[self.field.to_sym]
  end

  def model_field
    self.handler_class.user_segment_fields[self.field.to_sym][:field] if self.handler_class
  end

  def default_scope
    self.handler_class.user_segment_fields[self.field.to_sym][:scope] if self.handler_class
  end

  def handler
    @handler ||= UserSegment::FieldHandler.handlers.find { |info| info[:class].has_field?(self.field) } unless self.field.blank?
  end

  def handler=(handler)
    @handler = handler
  end

  def handler_class
    self.handler[:class] if self.handler
  end

  def domain_model_class
    self.handler[:domain_model_class] if self.handler
  end

  def end_user_field
    (self.handler[:end_user_field] || :end_user_id) if self.handler
  end

  def child_field
    return @child_field if @child_field
    return nil unless self.child
    return nil unless self.handler
    @child_field = UserSegment::Field.new self.child
    @child_field.handler = self.handler
    @child_field
  end

  def to_expr(opts={})
    output = "#{field}.#{operation}(" + self.arguments.collect do |arg|
      if arg.is_a?(String)
        "\"#{arg}\""
      elsif arg.is_a?(Time)
        "\"#{arg.strftime(Configuration.datetime_format)}\""
      elsif arg.is_a?(Date)
        "\"#{arg.strftime(Configuration.date_format)}\""
      elsif arg.is_a?(Array)
        '[' + arg.collect{ |v| v.is_a?(String) ? "\"#{v}\"" : v.to_s }.join(',') + ']'
      else
        arg.to_s
      end
    end.join(', ') + ")"

    output += '.' + self.child_field.to_expr if self.child && self.child_field && opts[:nochild].nil?
    output
  end

  def to_builder(opts={})
    options = self.to_h.slice(:field, :operation)
    self.arguments.each_with_index { |arg, idx| options["argument#{idx}".to_sym] = arg }
    if self.child_field
      options[:condition] = 'and'
      options[:child] = self.child_field.to_builder(opts)
    else
      options.merge!(opts)
    end
    options
  end
end
