require 'treetop'

class UserSegment::Filter

  def end_user_ids
    return [] unless self.valid?

    ids = nil
    self.operations.sort_by { |op| op.count }.each do |op|
      ids = op.end_user_ids(ids)
      return [] if ids.empty?
    end

    ids
  end

  def parser
    @parser ||= UserSegmentOptionParser.new
  end

  def failure_reason; @failure_reason; end

  def parse(text)
    if options = self.parser.parse(text)
      self.operations = options.eval
      true
    else
      @failure_reason = self.parser.failure_reason
      false
    end
  end

  def valid?
    return false unless self.operations
    line = 1
    self.operations.each do |op|
      unless op.valid?
        @failure_reason = "error on Line #{line}: " + op.error_on_field.failure_reasons.join("\n")
        return false
      end
      line = line.succ
    end
    true
  end

  def operations
    @operations
  end

  def operations=(options)
    @operations = options.collect do |line|
      UserSegment::Operation.new line[0], line[1..-1].collect { |op| UserSegment::Field.new op }
    end
  end

  def to_builder
    return {} unless @operations
    options = nil
    opts = {}
    @operations.reverse.each do |op|
      options = op.to_builder(opts)
      opts[:condition] = 'with'
      opts[:child] = options
    end
    options
  end

  def to_a
    return [] unless @operations
    @operations.collect { |op| op.to_a }
  end

  def to_expr
    return '' unless @operations
    @operations.collect { |op| op.to_expr }.join("\n")
  end
end
