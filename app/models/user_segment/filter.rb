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

  def parse(text)
    if options = self.parser.parse(text)
      self.operations = options.eval
      true
    else
      false
    end
  end

  def valid?
    return false unless self.operations
    self.operations.each { |op| return false unless op.valid? }
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
