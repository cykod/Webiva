
class EndUserSegmentType

  class GenderType < UserSegment::FieldType
    def self.gender_options
      [['Female', 'f'], ['Male', 'm']]
    end

    register_operation :is, [['Gender', :option, {:options => EndUserSegmentType::GenderType.gender_options, :form_field => 'radio_buttons'}]]

    def self.is(cls, field, gender)
      cls.scoped(:conditions => ["#{field} = ?", gender])
    end
  end

  class SourceType < UserSegment::FieldType
    def self.select_options
      EndUser.find(:all, :select => 'DISTINCT source').collect(&:source).sort
    end

    register_operation :is, [['Source', :model, {:class => EndUserSegmentType::SourceType}]]

    def self.is(cls, field, source)
      cls.scoped(:conditions => ["#{field} = ?", source])
    end
  end

  class LeadSourceType < UserSegment::FieldType
    def self.select_options
      EndUser.find(:all, :select => 'DISTINCT lead_source').collect(&:lead_source).sort
    end

    register_operation :is, [['Lead Source', :model, {:class => EndUserSegmentType::LeadSourceType}]]

    def self.is(cls, field, source)
      cls.scoped(:conditions => ["#{field} = ?", source])
    end
  end
end
