
class UserSegment < DomainModel

  serialize :segment_options
  serialize :fields

  def operations
    return @operations if @operations
    @operations = UserSegment::Operations.new
    @operations.operations = self.segment_options if self.segment_options
    @operations
  end

  def operations=(text)
    @operations = UserSegment::Operations.new
    @operations.parse text
  end

  def before_create
    self.order_by = 'created_at DESC' unless self.order_by
  end

  def before_save
    self.segment_options = self.operations.to_a if self.operations && self.operations.valid?
  end
end

