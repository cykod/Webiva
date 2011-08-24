
class UserSegment::CoreType

  @@datetime_format_options = [['Second/s', 'seconds'], ['Minute/s', 'minutes'], ['Hour/s', 'hours'], ['Day/s', 'days'], ['Week/s', 'weeks'], ['Month/s', 'months'], ['Year/s', 'years']]
  def self.datetime_format_options
    @@datetime_format_options
  end


  class DateTimeType < UserSegment::FieldType
    register_operation :before, [['Value', :integer], ['Format', :option, {:options => UserSegment::CoreType.datetime_format_options, :description => 'ago'}]]

    def self.before(cls, group_field, field, value, format)
      time = value.send(format).ago
      cls.scoped(:conditions => ["#{field} <= ?", time])
    end

    register_operation :since, [['Value', :integer], ['Format', :option, {:options => UserSegment::CoreType.datetime_format_options, :description => 'ago'}]]

    def self.since(cls, group_field, field, value, format)
      time = value.send(format).ago
      cls.scoped(:conditions => ["#{field} >= ?", time])
    end

    register_operation :between, [['From', :datetime], ['To', :datetime]]

    def self.between(cls, group_field, field, from, to)
      cls.scoped(:conditions => ["#{field} between ? and ?", from, to])
    end

    register_operation :range, [['Starts', :option, {:options => Content::Field.relative_date_start_options}], ['Ends', :option, {:options => Content::Field.relative_date_end_options}]], :default => true

    def self.range(cls, group_field, field, start_option, end_option)
      from = Content::Field.calculate_filter_start_date start_option
      to = Content::Field.calculate_filter_end_date from, end_option
      cls.scoped(:conditions => ["#{field} between ? and ?", from, to])
    end
  end

  @@number_type_operators = [['Greater than', '>'], ['Greater than or equal to', '>='], ['Equal to', '='], ['Less than or equal to', '<='], ['Lest than', '<']]
  def self.number_type_operators
    @@number_type_operators
  end

  class SimpleNumberType < UserSegment::FieldType
    register_operation :is, [['Operator', :option, {:options => UserSegment::CoreType.number_type_operators}], ['Value', :integer]]

    def self.is(cls, group_field, field, operator, value)
      cls.scoped(:conditions => ["#{field} #{operator} ?", value])
    end
  end

  class NumberType < UserSegment::FieldType
    register_operation :is, [['Operator', :option, {:options => UserSegment::CoreType.number_type_operators}], ['Value', :integer]]

    def self.is(cls, group_field, field, operator, value)
      cls.scoped(:conditions => ["#{field} #{operator} ?", value])
    end

    register_operation :sum, [['Operator', :option, {:options => UserSegment::CoreType.number_type_operators}], ['Value', :integer]], :complex => true

    def self.sum(cls, group_field, field, operator, value)
      cls.scoped(:select => "#{group_field}, SUM(#{field}) as #{field}_sum", :group => group_field, :having => "#{field}_sum #{operator} #{value}")
    end

    register_operation :average, [['Operator', :option, {:options => UserSegment::CoreType.number_type_operators}], ['Value', :integer]], :complex => true

    def self.average(cls, group_field, field, operator, value)
      cls.scoped(:select => "#{group_field}, AVG(#{field}) as #{field}_average", :group => group_field, :having => "#{field}_average #{operator} #{value}")
    end

    register_operation :min, [['Operator', :option, {:options => UserSegment::CoreType.number_type_operators}], ['Value', :integer]], :complex => true

    def self.min(cls, group_field, field, operator, value)
      cls.scoped(:select => "#{group_field}, MIN(#{field}) as #{field}_min", :group => group_field, :having => "#{field}_min #{operator} #{value}")
    end

    register_operation :max, [['Operator', :option, {:options => UserSegment::CoreType.number_type_operators}], ['Value', :integer]], :complex => true

    def self.max(cls, group_field, field, operator, value)
      cls.scoped(:select => "#{group_field}, MAX(#{field}) as #{field}_max", :group => group_field, :having => "#{field}_max #{operator} #{value}")
    end
  end

  class CountType < UserSegment::FieldType
    register_operation :count, [['Operator', :option, {:options => UserSegment::CoreType.number_type_operators}], ['Value', :integer]], :complex => true

    def self.count(cls, group_field, field, operator, value)
      cls.scoped(:select => "#{group_field}, COUNT(#{field}) as #{field}_count", :group => group_field, :having => "#{field}_count #{operator} #{value}")
    end
  end

  class StringType < UserSegment::FieldType
    register_operation :like, [['String', :string]], :name => 'Contains', :description => 'use % for wild card matches'

    def self.like(cls, group_field, field, string)
      cls.scoped(:conditions => ["#{field} like ?", string])
    end

    register_operation :is, [['String', :string]], :name => 'Matches', :description => 'exact match'

    def self.is(cls, group_field, field, string)
      cls.scoped(:conditions => ["#{field} = ?", string])
    end
  end


  class BooleanType < UserSegment::FieldType
    register_operation :is, [['Boolean', :boolean]]

    def self.is(cls, group_field, field, string)
      cls.scoped(:conditions => ["#{field} = ?", string])
    end
  end

  class MatchType < UserSegment::FieldType
    register_operation :search, [['Query', :string]], :description => 'full text search'

    def self.search(cls, group_field, field, query)
      cls.scoped(:conditions => ["MATCH (#{field}) AGAINST (?)", query])
    end
  end
end
