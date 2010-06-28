
class UserSegment::Operation

  def initialize(operator, fields)
    @operator = operator
    @fields = fields
  end

  def error_on_field; @error_on_field; end

  def valid?
    @fields.each do |fld|
      unless fld.valid?
        @error_on_field = fld
        return false
      end
    end
    true
  end

  def count
    @fields.collect do |fld|
      @operator == 'not' ? EndUser.count - fld.count : fld.count
    end.inject(0) { |sum, num| sum + num }
  end

  def end_user_ids(ids=nil)
    user_ids = []
    @fields.each { |fld| user_ids = user_ids + fld.end_user_ids(ids) }
    user_ids.uniq!

    if @operator == 'not'
      if ids
        user_ids = ids - user_ids
      else
        user_ids = (user_ids.empty? ? EndUser.find(:all, :select => 'id') : EndUser.find(:all, :select => 'id', :conditions => ['id NOT IN(?)', user_ids])).collect &:id
      end
    end

    user_ids
  end

  def to_builder(opts={})
    options = nil
    @fields.reverse.each do |fld|
      options = fld.to_builder(opts)
      opts[:condition] = 'or'
      opts[:child] = options
    end
    options[:operator] = @operator
    options
  end

  def to_a
    [@operator] + @fields.collect { |fld| fld.to_h }
  end

  def to_expr
    output = @operator == 'not' ? 'not ' : ''
    output += @fields.collect { |fld| fld.to_expr }.join(' + ')
    output
  end
end
