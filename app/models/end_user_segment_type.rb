
class EndUserSegmentType

  class GenderType < UserSegment::FieldType
    include HandlerActions

    def self.gender_options
      [['Female', 'f'], ['Male', 'm']]
    end

    register_operation :is, [['Gender', :option, {:options => EndUserSegmentType::GenderType.gender_options, :form_field => 'radio_buttons'}]]

    def self.is(cls, field, gender)
      cls.scoped(:conditions => ["#{field} = ?", gender])
    end
  end
end
