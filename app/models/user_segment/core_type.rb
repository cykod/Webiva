
class UserSegment::CoreType

  @@datetime_format_options = ['second', 'seconds', 'minute', 'minutes', 'hour', 'hours', 'day', 'days', 'week', 'weeks', 'month', 'months', 'year', 'years']
  def self.datetime_format_options
    @@datetime_format_options
  end


  class DateTimeType < UserSegment::FieldType
    register_operation :before, [['Value', :integer], ['Format', :option, {:options => UserSegment::CoreType.datetime_format_options, :description => 'ago'}]]

    def self.before(cls, field, value, format)
      time = value.send(format).ago
      cls.scoped(:conditions => ["#{field} <= ?", time])
    end

    register_operation :since, [['Value', :integer], ['Format', :option, {:options => UserSegment::CoreType.datetime_format_options, :description => 'ago'}]]

    def self.since(cls, field, value, format)
      time = value.send(format).ago
      cls.scoped(:conditions => ["#{field} >= ?", time])
    end

    register_operation :between, [['From', :datetime], ['To', :datetime]]

    def self.between(cls, field, from, to)
      cls.scoped(:conditions => ["#{field} between ? and ?", from, to])
    end
  end


  class NumberType < UserSegment::FieldType
    register_operation :greater_than, [['Value', :integer]]

    def self.greater_than(cls, field, value)
      cls.scoped(:conditions => ["#{field} > ?", value])
    end

    register_operation :greater_than_or_equal_to, [['Value', :integer]]

    def self.greater_than_or_equal_to(cls, field, value)
      cls.scoped(:conditions => ["#{field} >= ?", value])
    end

    register_operation :less_than, [['Value', :integer]]

    def self.less_than(cls, field, value)
      cls.scoped(:conditions => ["#{field} < ?", value])
    end

    register_operation :less_than_or_equal_to, [['Value', :integer]]

    def self.less_than_or_equal_to(cls, field, value)
      cls.scoped(:conditions => ["#{field} <= ?", value])
    end

    register_operation :equals, [['Value', :integer]]

    def self.equals(cls, field, value)
      cls.scoped(:conditions => ["#{field} = ?", value])
    end

    register_operation :is, [['Value', :integer]]

    def self.is(cls, field, value)
      self.equals(cls, field, value)
    end
  end

  class StringType < UserSegment::FieldType
    register_operation :like, [['String', :string]], :description => 'use % for wild card matches'

    def self.like(cls, field, string)
      cls.scoped(:conditions => ["#{field} like ?", string])
    end

    register_operation :is, [['String', :string]], :description => 'exact match'

    def self.is(cls, field, string)
      cls.scoped(:conditions => ["#{field} = ?", string])
    end
  end

  class BooleanType < UserSegment::FieldType
    register_operation :is, [['Boolean', :boolean]]

    def self.is(cls, field, string)
      cls.scoped(:conditions => ["#{field} = ?", string])
    end
  end

  class MatchType < UserSegment::FieldType
    register_operation :search, [['Query', :string]], :description => 'full text search'

    def self.search(cls, field, query)
      cls.scoped(:conditions => ["MATCH (#{field}) AGAINST (?)", query])
    end
  end
end
