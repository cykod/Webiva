
class EndUserActionSegmentType

  class ActionType < UserSegment::FieldType
    include HandlerActions

    def self.select_options(opts={})
      self.get_handlers(:action).collect { |handler| [handler[1][:description], handler[1][:handler].to_s] }
    end

    register_operation :is, [['Action', :model, {:class => EndUserActionSegmentType::ActionType}]]

    def self.is(cls, field, path)
      path = path.split('/')
      cls.scoped(:conditions => ["renderer = ? and action = ?", path[0..-2].join('/'), path[-1]])
    end
  end
end
