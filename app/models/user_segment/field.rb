
class UserSegment::Field < HashModel
  attributes :field => nil, :operation => nil, :arguments => [], :child => nil

  validates_presence_of :field
  validates_presence_of :operation

  def strict?; true; end

  def validate
    unless self.field.blank?
      self.errors.add(:field, 'invalid field') unless self.handler
    end

    unless self.operation.blank?
      self.errors.add(:operation, 'invalid operation') if ! self.type_class || ! self.type_class.has_operation?(self.operation)

      if self.operation_info
        self.errors.add(:arguments, 'are missing') if self.arguments.empty? && ! self.operation_arguments.empty?

        unless self.arguments.empty?
          self.errors.add(:arguments, 'are incorrect') unless self.arguments.size == self.operation_arguments.size
          self.errors.add(:arguments, 'are invalid') if self.arguments.size == self.operation_arguments.size && ! self.valid_arguments?
        end
      end
    end

    self.errors.add(:child, 'is invalid') if self.child && self.child_field && ! self.child_field.valid?
  end

  def count
    @count ||= self.get_scope.count
  end

  def end_user_ids(ids=nil)
    return @end_user_ids if @end_user_ids
    scope = self.get_scope
    scope = scope.scoped(:conditions => {self.end_user_field  => ids}) if ids
    @end_user_ids = scope.find(:all, :select => self.end_user_field).collect &self.end_user_field
  end

  def get_scope(scope=nil)
    return @scope if @scope
    scope ||= self.domain_model_class
    @scope = self.type_class.send(self.operation, scope, self.model_field, *self.converted_arguments)
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
    @operation_info ||= self.type_class.user_segment_field_type_operations[self.operation.to_sym] if self.type_class
  end

  def type_class
    @type_class ||= self.handler_class.user_segment_fields[self.field.to_sym][:type] if self.handler_class && self.handler_class.user_segment_fields && self.handler_class.user_segment_fields[self.field.to_sym]
  end

  def model_field
    self.handler_class.user_segment_fields[self.field.to_sym][:field] if self.handler_class
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
    output = "#{field}.#{operation}(" + self.arguments.collect { |arg| arg.is_a?(String) || arg.is_a?(Time) ? "\"#{arg}\"" : arg.to_s }.join(', ') + ")"
    output += '.' + self.child_field.to_expr if self.child && self.child_field && opts[:nochild].nil?
    output
  end
end
