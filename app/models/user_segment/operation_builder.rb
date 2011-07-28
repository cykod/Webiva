
class UserSegment::OperationBuilder < HashModel
  attributes :operator => nil, :field => nil, :operation => nil, :arguments => nil, :condition => nil, :parent => nil, :index => 1, :previous_operator => nil

  def strict?; true; end
  def arguments; @arguments ||= []; end

  def operator_options
    [['Not', 'not'], ['', nil]]
  end

  def condition_options
    [['Select function', nil], ['Combined', 'and'], ['Or', 'or'], ['And', 'with']]
  end

  def validate
    self.errors.add(:field, 'is invalid') unless self.user_segment_field.valid?
    self.errors.add(:condition, 'is invalid') unless self.condition_options.rassoc(self.condition)
    self.errors.add(:condition, 'is invalid') if ! self.condition.blank? && ! self.child_field.valid?
  end

  def build(opts={})
    self.operator = opts[:operator]
    self.previous_operator = opts[:previous_operator]
    self.operator = nil if self.operator.blank?
    self.field = opts[:field]
    self.operation = opts[:operation]
    self.condition = opts[:condition]
    self.condition = nil if self.condition.blank?
    self.parent = opts[:parent]
    unless self.operation_options.empty?
      unless self.operation_options.rassoc(self.operation)
        self.operation = self.operation_options[0][1]
        @user_segment_field = nil
      end
    end

    self.operation_arguments.each_with_index do |type, idx|
      arg = "argument#{idx}"
      self.send("#{arg}=", opts[arg.to_sym]) unless opts[arg.to_sym].nil?
    end

    if ! self.condition.blank?
      parent = self.condition == 'and' ? self : nil
      child = (opts[:child] || {}).merge(:parent => parent, :previous_operator => self.operator || self.previous_operator)
      self.child_field.build(child)
      self.user_segment_field.child = self.child_field.user_segment_field.to_h if self.condition == 'and'
    end
  end

  def field_options
    return @field_options if @field_options
    @field_options = []
    UserSegment::FieldHandler.handlers.each do |handler|
      if self.parent.nil? || self.parent.user_segment_field.handler == handler
        handler[:class].user_segment_fields.each do |field, values|
          @field_options << [values[:name], field.to_s] unless @field_options.rassoc(field.to_s)
        end
      end
    end
    @field_options = [['Select a field', nil]] + @field_options.sort { |a, b| a[0] <=> b[0] }
  end

  def field_group_options
    return @field_group_options if @field_group_options
    @field_group_options = []
    seen_options = {}
    UserSegment::FieldHandler.handlers.each do |handler|
      if self.parent.nil? || self.parent.user_segment_field.handler == handler
        options = []
        handler[:class].user_segment_fields.each do |field, values|
          next if values[:combined_only] && self.parent.nil?
          options << ['-  ' + values[:name], field.to_s] unless seen_options[field.to_s]
          seen_options[field.to_s] = 1
        end
        options.sort! { |a, b| a[0] <=> b[0] }
        @field_group_options << [handler[:name], options]
      end
    end
    @field_group_options = [['', [['Select a field', nil]]]] + @field_group_options
  end

  def user_segment_field
    return @user_segment_field if @user_segment_field
    @user_segment_field = UserSegment::Field.new :field => self.field, :operation => self.operation, :arguments => self.arguments
  end

  def already_complex
    if self.parent && self.parent.condition == 'and'
      self.parent.user_segment_field.complex_operation || self.parent.already_complex
    else
      false
    end
  end

  def field_builder_name
    self.user_segment_field.builder_name if self.user_segment_field
  end

  def field_builder_description 
    self.user_segment_field.type_class.user_segment_field_type_operations[operation.to_sym][:description] if self.user_segment_field.type_class.user_segment_field_type_operations[operation.to_sym]
  end

  def operation_options
    return @operation_options if @operation_options
    @operation_options = []

    is_complex = self.already_complex

    if self.user_segment_field.type_class
      @operation_options = self.user_segment_field.type_class.user_segment_field_type_operations.collect do |operation, values|
        if is_complex && values[:complex]
          nil
        else
          [values[:name], operation.to_s]
        end
      end.compact
    end

    @operation_options.sort! { |a, b| a[0] <=> b[0] }
    @operation_options
  end

  def operation_arguments
    self.user_segment_field.operation_arguments || []
  end

  def operation_argument_names
    self.user_segment_field.operation_argument_names
  end

  def operation_argument_options
    self.user_segment_field.operation_argument_options
  end

  def convert_to(value, idx)
    UserSegment::FieldType.convert_to(value, self.operation_arguments[idx], self.operation_argument_options[idx])
  end

  def method_missing(arg, *args)
    arg = arg.to_s
    if arg =~ /^argument(\d+)$/
      val = self.arguments[$1.to_i]
      val = val.strftime(Configuration.datetime_format) if val.is_a?(Time)
      val
    elsif arg =~ /^argument(\d+)=$/
      self.arguments[$1.to_i] = self.convert_to(args[0], $1.to_i) if $1.to_i < self.operation_arguments.length
    else
      super
    end
  end

  def to_expr
    return '' unless self.valid?
    output = self.operator == 'not' ? 'not ' : ''
    output += self.user_segment_field.to_expr(:nochild => 1)
    output += '.' + self.child_field.to_expr if self.condition == 'and'
    output += ' + ' + self.child_field.to_expr if self.condition == 'or'
    output += "\n" + self.child_field.to_expr if self.condition == 'with'
    output
  end

  def child_field
    @child_field ||= UserSegment::OperationBuilder.new :index => self.index+1
  end

  def self.create_builder(user_segment)
    builder = UserSegment::OperationBuilder.new nil
    builder.build(user_segment.operations.to_builder)
    builder
  end

  def self.prebuilt_filters
    [
      ['New registered users in the last week', {:field => 'registered', :operation => 'is', :argument0 => true, :condition => 'and', :child => {:field => 'created', :operation => 'since', :argument0 => 1, :argument1 => 'weeks'}}],
      ['Users that have not logged in the last 7 days', {:operator => 'not', :field => 'user_action', :operation => 'is', :argument0 => '/editor/auth/login', :condition => 'and', :child => {:field => 'occurred', :operation => 'since', :argument0 => 7, :argument1 => 'days'}}]
    ]
  end

  def self.prebuilt_filters_options
    self.prebuilt_filters.collect { |filter| [filter[0], filter[0].gsub(/[^a-zA-Z0-9]/, '').downcase] }
  end

  def self.get_prebuilt_filter(filter)
    value = self.prebuilt_filters.find { |f| f[0].gsub(/[^a-zA-Z0-9]/, '').downcase == filter }
    value ? value[1] : {}
  end
end
