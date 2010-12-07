
class DomainLogEntrySegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'Domain Log Entry Fields',
      :domain_model_class => DomainLogEntry,
      :end_user_field => :user_id
    }
  end

  class SiteNodeType < UserSegment::FieldType
    def self.select_options
      SiteNode.page_options
    end

    register_operation :is, [['Site Node', :model, {:class => DomainLogEntrySegmentField::SiteNodeType}]]

    def self.is(cls, group_field, field, node)
      cls.scoped(:conditions => ["#{field} = ?", node])
    end

    register_operation :count, [['Site Node', :model, {:class => DomainLogEntrySegmentField::SiteNodeType}], ['Operator', :option, {:options => UserSegment::CoreType.number_type_operators}], ['Value', :integer]], :complex => true

    def self.count(cls, group_field, field, node, operator, value)
      cls.scoped(:select => "#{group_field}, COUNT(#{field}) as #{field}_count", :conditions => ["#{field} = ?", node], :group => group_field, :having => "#{field}_count #{operator} #{value}")
    end
  end

  class ContentNodeType < UserSegment::FieldType
    def self.select_options
      ContentNodeValue.find(:all, :conditions => ['link IS NOT NULL'], :select => 'DISTINCT content_node_id, link', :limit => 10000).collect { |v| [v.link, v.content_node_id] }.sort { |a, b| a[0] <=> b[0] }
    end

    register_operation :is, [['Content', :model, {:class => DomainLogEntrySegmentField::ContentNodeType}]]

    def self.is(cls, group_field, field, action)
      cls.scoped(:conditions => ["#{field} = ?", action])
    end

    register_operation :count, [['ContentNodeType', :model, {:class => DomainLogEntrySegmentField::ContentNodeType}], ['Operator', :option, {:options => UserSegment::CoreType.number_type_operators}], ['Value', :integer]], :complex => true

    def self.count(cls, group_field, field, node, operator, value)
      cls.scoped(:select => "#{group_field}, COUNT(#{field}) as #{field}_count", :conditions => ["#{field} = ?", node], :group => group_field, :having => "#{field}_count #{operator} #{value}")
    end
  end

  register_field :log_occurred, UserSegment::CoreType::DateTimeType, :field => :occurred_at, :name => 'Log: Occurred'
  register_field :log_content, DomainLogEntrySegmentField::ContentNodeType, :field => :content_node_id, :name => 'Log: Content', :combined_only => true
  register_field :log_site_node, DomainLogEntrySegmentField::SiteNodeType, :field => :site_node_id, :name => 'Log: Site Node', :combined_only => true
  register_field :log_user_level, EndUserSegmentType::UserLevelType, :field => :user_level, :name => 'Log: User Level', :combined_only => true
  register_field :log_value, UserSegment::CoreType::NumberType, :field => :value, :name => 'Log: Value', :combined_only => true
end
