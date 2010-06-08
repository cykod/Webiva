
class EndUserCacheSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'User Cache Fields',
      :domain_model_class => EndUserCache
    }
  end

  register_field :cache, UserSegment::CoreType::MatchType, :field => :data, :name => 'Cache', :search_only => true
end
