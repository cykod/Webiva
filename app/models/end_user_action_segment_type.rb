
class EndUserActionSegmentType

  class UserActionType < UserSegment::FieldType
    include HandlerActions

    def self.select_options
      self.get_handlers(:action).collect { |handler| [handler[1][:description], handler[1][:handler].to_s] }
    end

    register_operation :is, [['Action', :model, {:class => EndUserActionSegmentType::UserActionType}]]

    def self.is(cls, group_field, field, path)
      path = path.split('/')
      cls.scoped(:conditions => ["#{field[0]} = ? and #{field[1]} = ?", path[0..-2].join('/').sub(/^\//, ''), path[-1]])
    end
  end

  class ActionType < UserSegment::FieldType

    def self.select_options
      EndUserAction.find(:all, :select => 'DISTINCT action').collect(&:action).sort
    end

    register_operation :is, [['Action', :model, {:class => EndUserActionSegmentType::ActionType}]]

    def self.is(cls, group_field, field, action)
      cls.scoped(:conditions => ["#{field} = ?", action])
    end
  end

  class RendererType < UserSegment::FieldType

    def self.select_options
      EndUserAction.find(:all, :select => 'DISTINCT renderer').collect(&:renderer).sort
    end

    register_operation :is, [['Renderer', :model, {:class => EndUserActionSegmentType::RendererType}]]

    def self.is(cls, group_field, field, renderer)
      cls.scoped(:conditions => ["#{field} = ?", renderer])
    end
  end
end
