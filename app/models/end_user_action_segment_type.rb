
class EndUserActionSegmentType

  class UserActionType < UserSegment::FieldType
    include HandlerActions

    def self.select_options
      self.get_handlers(:action).collect { |handler| [handler[1][:description], handler[1][:handler].to_s] }
    end

    register_operation :is, [['Action', :model, {:class => EndUserActionSegmentType::UserActionType}]]

    def self.is(cls, group_field, field, path)
      path = path.split('/')
      cls.where(field[0] => path[0..-2].join('/').sub(/^\//, ''), field[1] => path[-1])
    end
  end

  class ActionType < UserSegment::FieldType

    def self.select_options
      EndUserAction.select('DISTINCT action').all.collect(&:action).sort
    end

    register_operation :is, [['Action', :model, {:class => EndUserActionSegmentType::ActionType}]]

    def self.is(cls, group_field, field, action)
      cls.where(field => action)
    end
  end

  class RendererType < UserSegment::FieldType

    def self.select_options
      EndUserAction.select('DISTINCT renderer').all.collect(&:renderer).sort
    end

    register_operation :is, [['Renderer', :model, {:class => EndUserActionSegmentType::RendererType}]]

    def self.is(cls, group_field, field, renderer)
      cls.where(field => renderer)
    end
  end
end
