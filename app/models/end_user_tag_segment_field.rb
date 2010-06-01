
class EndUserTagSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'User Tag Fields',
      :domain_model_class => EndUserTag
    }
  end

  class EndUserTagType < UserSegment::FieldType
    register_operation :is, [['Tag', :model, {:class => EndUserTagSegmentField::EndUserTagType}]]

    def self.select_options
      Tag.find(:all, :select => 'name').collect(&:name).sort.collect { |name| [name, name] }
    end

    def self.is(cls, field, name)
      tg = Tag.find_by_name name
      id = tg ? tg.id : 0
      cls.scoped(:conditions => ["#{field} = ?", id])
    end
  end

  register_field :tag, EndUserTagSegmentField::EndUserTagType, :field => :tag_id, :name => 'Tag'
end
