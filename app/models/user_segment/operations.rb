require 'treetop'

class UserSegment::Operations

  def end_user_ids
    return @end_user_ids if @end_user_ids
    return [] unless self.valid?

    self.operations.sort_by { |op| op.count }.each do |op|
      @end_user_ids = op.end_user_ids(@end_user_ids)
      return [] if @end_user_ids.empty?
    end

    @end_user_ids
  end

  def parser
    @parser ||= UserSegmentOptionParser.new
  end

  def parse(text)
    if options = self.parser.parse(text)
      self.operations = options.eval
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

  def to_a
    return [] unless @operations
    @operations.collect { |op| op.to_a }
  end
end
